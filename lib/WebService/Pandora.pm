package WebService::Pandora;

use strict;
use warnings;

use JSON;
use HTTP::Request;
use LWP::UserAgent;

our $VERSION = '0.1';

use constant WEBSERVICE_URL => 'https://tuner.pandora.com/services/json/';
use constant WEBSERVICE_VERSION => "5";

sub new {

    my $caller = shift;

    my $class = ref( $caller );
    $class = $caller if ( !$class );

    my $self = {'timeout' => undef,
                'error' => '',
                @_};

    $self->{'ua'} = LWP::UserAgent->new( timeout => $self->{'timeout'} );
    $self->{'json'} = JSON->new();

    bless( $self, $class );

    return $self;
}

sub partnerLogin {

    my ( $self, %args ) = @_;

    my $username = $args{'username'};
    my $password = $args{'password'};
    my $deviceModel = $args{'deviceModel'};

    # make sure all required arguments given
    if ( !defined( $username ) ||
	 !defined( $password ) ||
	 !defined( $deviceModel ) ) {

	$self->{'error'} = 'username, password, and deviceModel must all be provided.';
	return;
    }

    # create our POST request
    my $url = WEBSERVICE_URL . "?method=auth.partnerLogin";
    my $request = HTTP::Request->new( 'POST' => $url );

    # craft the JSON data for the request
    my $json = $self->{'json'}->encode( {'username' => $username,
					 'password' => $password,
					 'deviceModel' => $deviceModel,
					 'version' => WEBSERVICE_VERSION,
					 'includeUrls' => JSON::true} );

    # set the header and content of the request
    $request->header( 'Content-Type' => 'application/json' );
    $request->content( $json );

    # issue the request
    my $response = $self->{'ua'}->request( $request );

    # detect error issuing request
    if ( !$response->is_success() ) {

	$self->{'error'} = $response->status_line();
	return;
    }

    return $self->{'json'}->decode( $response->decoded_content() );
}

sub userLogin {

    my ( $self, %args ) = @_;

    my $username = $args{'username'};
    my $password = $args{'password'};
    my $partner_id = $args{'partner_id'};
    my $user_id = $args{'user_id'},
    my $partnerAuthToken = $args{'partnerAuthToken'};

    # make sure all required arguments given
    if ( !defined( $username ) ||
	 !defined( $password ) ||
	 !defined( $partner_id ) ||
	 #!defined( $user_id ) ||
	 !defined( $partnerAuthToken ) ) {

	$self->{'error'} = 'username, password, partner_id, and partnerAuthToken must all be provided.';
	return;
    }

    # create our POST request
    my $url = WEBSERVICE_URL . "?method=auth.userLogin&partner_id=20";
    my $request = HTTP::Request->new( 'POST' => $url );

    # craft the JSON data for the request
    my $json = $self->{'json'}->encode( {'loginType' => 'user',
					 'username' => $username,
					 'password' => $password,
					 'partnerAuthToken' => $partnerAuthToken,
					 'includePandoraOneInfo' => JSON::true,
					 'includeSubscriptionExpiration' => JSON::true,
					 'includeAdAttributes' => JSON::true,
					 'returnStationList' => JSON::true,
					 'includeStationArtUrl' => JSON::true,
					 'returnGenreStations' => JSON::true,
					 'includeDemographics' => JSON::true,
					 'returnCapped' => JSON::true} );

    # set the header and content of the request
    $request->header( 'Content-Type' => 'application/json' );
    $request->content( $json );

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

    my ( $self ) = @_;

    return $self->{'error'};
}

1;
