package WebService::Pandora::Partner;

use strict;
use warnings;

use WebService::Pandora::Method;
use Data::Dumper;

use constant WEBSERVICE_VERSION => '5';

### constructor ###

sub new {

    my $caller = shift;
    
    my $class = ref( $caller );
    $class = $caller if ( !$class );
    
    my $self = {'username' => undef,
                'password' => undef,
                'deviceModel' => undef,
		'decryption_key' => undef,
		'encryption_key' => undef,
		'host' => undef,
                @_};

    bless( $self, $class );

    return $self;
}

### getters/setters ###

sub error {

    my ( $self, $error ) = @_;

    $self->{'error'} = $error if ( defined( $error ) );

    return $self->{'error'};
}

### public methods ###

sub login {

    my ( $self ) = @_;

    # create the auth.partnerLogin method
    my $method = WebService::Pandora::Method->new( name => 'auth.partnerLogin',
						   encrypt => 0,
						   ssl => 1,
						   host => $self->{'host'},
						   params => {'username' => $self->{'username'},
							      'password' => $self->{'password'},
							      'deviceModel' => $self->{'deviceModel'},
							      'version' => "5"} );
							      
    my $result = $method->execute();

    # detect error
    if ( !$result ) {

	$self->error( $method->error() );
	return;
    }

    return $result;
}

1;
