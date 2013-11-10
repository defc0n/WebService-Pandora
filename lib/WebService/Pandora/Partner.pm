package WebService::Pandora::Partner;

use strict;
use warnings;

sub new {

    my $caller = shift;
    
    my $class = ref( $caller );
    $class = $caller if ( !$class );
    
    my $self = {'username' => undef,
                'password' => undef,
                'device_id' => undef,
		'decryption_key' => undef,
		'encryption_key' => undef,
		'host' => undef,
                @_};

    bless( $self, $class );

    return $self;
}

sub username {

    my ( $self, $username ) = @_;

    $self->{'username'} = $username if ( defined( $username ) );

    return $self->{'username'};
}

sub password {

    my ( $self, $password ) = @_;

    $self->{'password'} = $password if ( defined( $password ) );

    return $self->{'password'};
}

sub device_id {

    my ( $self, $device_id ) = @_;

    $self->{'device_id'} = $device_id if ( defined( $device_id ) );

    return $self->{'device_id'};
}

sub decryption_key {

    my ( $self, $decryption_key ) = @_;

    $self->{'decryption_key'} = $decryption_key if ( defined( $decryption_key ) );

    return $self->{'decryption_key'};
}

sub encryption_key {

    my ( $self, $encryption_key ) = @_;

    $self->{'encryption_key'} = $encryption_key if ( defined( $encryption_key ) );

    return $self->{'encryption_key'};
}

sub host {

    my ( $self, $host ) = @_;

    $self->{'host'} = $host if ( defined( $host ) );

    return $self->{'host'};
}

1;
