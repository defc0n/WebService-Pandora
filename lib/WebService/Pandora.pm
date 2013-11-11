package WebService::Pandora;

use strict;
use warnings;

use WebService::Pandora::Method;
use WebService::Pandora::Cryptor;
use WebService::Pandora::Partner::iOS;

use JSON;
use HTTP::Request;
use LWP::UserAgent;
use URI::Escape;
use Data::Dumper;

our $VERSION = '0.1';

use constant WEBSERVICE_URL => 'tuner.pandora.com/services/json/';
use constant WEBSERVICE_VERSION => "5";

sub new {

    my $caller = shift;

    my $class = ref( $caller );
    $class = $caller if ( !$class );

    my $self = {'username' => undef,
		'password' => undef,
		'timeout' => undef,
		'partner' => undef,
                @_};

    # be nice and default to iOS partner if one wasn't given..
    if ( !defined( $self->{'partner'} ) ) {

	$self->{'partner'} = WebService::Pandora::Partner::iOS->new();
    }

    # create and store cryptor object, using the partner's encryption keys
    my $cryptor = WebService::Pandora::Cryptor->new( decryption_key => $self->{'partner'}->decryption_key(),
						     encryption_key => $self->{'partner'}->encryption_key() );
    $self->{'cryptor'} = $cryptor;

    bless( $self, $class );

    return $self;
}

sub login {

    my ( $self ) = @_;

    # first, do the partner login
    my $ret = $self->{'partner'}->login();

    # detect error
    if ( !$ret ) {

	# return the error message from the partner
	$self->error( $self->{'partner'}->error() );
	return;
    }

    # store the important attributes we got back as we'll need them later
    $self->{'partner_auth_token'} = $ret->{'partner_auth_token'};
    $self->{'partner_id'} = $ret->{'partner_id'};
    $self->{'sync_time'} = $ret->{'sync_time'};

    # handle special case of decrypting the sync time
    $self->{'sync_time'} = $self->{'cryptor'}->decrypt( $self->{'sync_time'} );
    $self->{'sync_time'} = substr( $self->{'sync_time'}, 4 );

    # now create and execute the method for the user login request
    my $method = WebService::Pandora::Method->new( name => 'auth.userLogin',
						   partner_auth_token => $self->{'partner_auth_token'},
						   partner_id => $self->{'partner_id'},
						   sync_time => $self->{'sync_time'},
						   host => $self->{'partner'}->host(),
						   ssl => 1,
						   encrypt => 1,
						   cryptor => $self->{'cryptor'},
						   params => {'loginType' => 'user',
							      'username' => $self->{'username'},
							      'password' => $self->{'password'},
							      'partnerAuthToken' => $self->{'partner_auth_token'}} );

    $ret = $method->execute();
    
    # detect error
    if ( !$ret ) {

	$self->error( $method->error() );
	return;
    }

    # store even more attributes we'll need later
    $self->{'user_id'} = $ret->{'userId'};
    $self->{'user_auth_token'} = $ret->{'userAuthToken'};

    # success
    return 1;
}

sub get_station_list {

    my ( $self, %args ) = @_;

    # create the user.getStationList method w/ appropriate params
    my $method = WebService::Pandora::Method->new( name => 'user.getStationList',
						   partner_auth_token => $self->{'partner_auth_token'},
						   user_auth_token => $self->{'user_auth_token'},
						   partner_id => $self->{'partner_id'},
						   user_id => $self->{'user_id'},
						   sync_time => $self->{'sync_time'},
						   host => $self->{'partner'}->host(),
						   ssl => 0,
						   encrypt => 1,
						   cryptor => $self->{'cryptor'},
						   params => {} );

    my $ret = $method->execute();

    if ( !$ret ) {

	$self->error( $method->error() );
	return;
    }

    return $ret;
}

sub getStation {

    my ( $self, %args ) = @_;

    my $partner_id = $args{'partner_id'};
    my $user_id = $args{'user_id'};
    my $userAuthToken = $args{'userAuthToken'};
    my $syncTime = $args{'syncTime'};
    my $stationToken = $args{'stationToken'};

    # make sure all required arguments given
    if ( !defined( $user_id ) ||
         !defined( $userAuthToken ) ||
         !defined( $partner_id ) ||
         !defined( $syncTime ) ||
         !defined( $stationToken ) ) {

        $self->{'error'} = 'user_id, userAuthToken, partner_id, stationToken, and syncTime must all be provided.';
        return;
    }

    # create our POST request
    my $url = $self->request_url( ssl => 0,
                                  params => {'method' => "station.getStation",
                                             'partner_id' => $partner_id,
                                             'auth_token' => $userAuthToken,
                                             'user_id' => $user_id } );

    my $request = HTTP::Request->new( 'POST' => $url );

    # craft the JSON data for the request
    my $json = $self->{'json'}->encode( {'includeExtendedAttributes' => JSON::true,
                                         'userAuthToken' => $userAuthToken,
                                         'stationToken' => $stationToken,
                                         'syncTime' => $syncTime} );

    # set the header and content of the request
    $request->header( 'Content-Type' => 'application/json' );
    $request->content( $self->encrypt( $json ) );

    # issue the request
    my $response = $self->{'ua'}->request( $request );

    # detect error issuing request
    if ( !$response->is_success() ) {

        $self->{'error'} = $response->status_line();
        return;
    }

    return $self->{'json'}->decode( $response->decoded_content() );
}

sub error {

    my ( $self, $error ) = @_;

    $self->{'error'} = $error if ( defined( $error ) );

    return $self->{'error'};
}

sub request_url {

    my ( $self, %args ) = @_;

    my $ssl = $args{'ssl'};
    my $params = $args{'params'};

    my $protocol = 'http://';

    $protocol = 'https://' if ( $ssl );

    my $url = $protocol . WEBSERVICE_URL . "?";

    my @params;

    while ( my ( $arg, $value ) = each( %$params ) ) {

        push( @params, uri_escape( $arg ) . "=" . uri_escape( $value ) );
    }

    $url .= join( "&", @params );

    return $url;
}

1;
