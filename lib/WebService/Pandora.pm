package WebService::Pandora;

use strict;
use warnings;

use JSON;
use HTTP::Request;
use LWP::UserAgent;
use Crypt::ECB;
use Data::Dumper;

our $VERSION = '0.1';

use constant WEBSERVICE_URL => 'https://tuner.pandora.com/services/json/';
use constant WEBSERVICE_VERSION => "5";

sub new {

    my $caller = shift;

    my $class = ref( $caller );
    $class = $caller if ( !$class );

    my $self = {'timeout' => undef,
		'encryption_key' => undef,
		'decryption_key' => undef,
                'error' => '',
                @_};

    # create and store LWP object
    $self->{'ua'} = LWP::UserAgent->new( timeout => $self->{'timeout'} );

    # create and store JSON object
    $self->{'json'} = JSON->new();

    # create and store cryptor object
    my $cryptor = Crypt::ECB->new();

    $cryptor->padding( PADDING_AUTO );
    $cryptor->cipher( 'Blowfish' );

    $self->{'cryptor'} = $cryptor;

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

    my $result = $self->{'json'}->decode( $response->decoded_content() );

    # decrypt and skip first 4 bytes/characters of the syncTime
    if ( defined( $result->{'result'}{'syncTime'} ) ) {

	$result->{'result'}{'syncTime'} = substr( $self->decrypt( $result->{'result'}{'syncTime'} ), 4);
    }

    return $result;
}

sub userLogin {

    my ( $self, %args ) = @_;

    my $username = $args{'username'};
    my $password = $args{'password'};
    my $partnerAuthToken = $args{'partnerAuthToken'};
    my $partner_id = $args{'partner_id'};
    my $syncTime = $args{'syncTime'};

    # make sure all required arguments given
    if ( !defined( $username ) ||
	 !defined( $password ) ||
	 !defined( $partnerAuthToken ) ||
	 !defined( $partner_id ) ||
	 !defined( $syncTime ) ) {

	$self->{'error'} = 'username, password, partnerAuthToken, partner_id, and syncTime must all be provided.';
	return;
    }

    # create our POST request
    my $url = WEBSERVICE_URL . "?method=auth.userLogin&partner_id=$partner_id&auth_token=$partnerAuthToken";
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
					 'returnCapped' => JSON::true,
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
    
    my ( $self ) = @_;
    
    return $self->{'error'};
}

sub encrypt {

    my ( $self, $data ) = @_;

    $self->{'cryptor'}->key( $self->{'encryption_key'} );

    return $self->{'cryptor'}->encrypt_hex( $data );
}

sub decrypt {

    my ( $self, $data ) = @_;

    $self->{'cryptor'}->key( $self->{'decryption_key'} );

    return $self->{'cryptor'}->decrypt_hex( $data );
}

1;
