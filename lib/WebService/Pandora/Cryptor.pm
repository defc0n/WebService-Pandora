package WebService::Pandora::Cryptor;

use strict;
use warnings;

use Crypt::ECB;
use Data::Dumper;

sub new {

    my $caller = shift;

    my $class = ref( $caller );
    $class = $caller if ( !$class );

    my $self = {'encryption_key' => undef,
                'decryption_key' => undef,
                @_};

    bless( $self, $class );

    my $crypt = Crypt::ECB->new();
    
    $crypt->padding( PADDING_AUTO );
    $crypt->cipher( 'Blowfish' );

    $self->{'crypt'} = $crypt;

    return $self;
}

sub encrypt {

    my ( $self, $data ) = @_;

    $self->{'crypt'}->key( $self->{'encryption_key'} );

    return $self->{'crypt'}->encrypt_hex( $data );
}

sub decrypt {

    my ( $self, $data ) = @_;

    $self->{'crypt'}->key( $self->{'decryption_key'} );

    return $self->{'crypt'}->decrypt_hex( $data );
}

1;
