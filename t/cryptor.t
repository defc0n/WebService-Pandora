use strict;
use warnings;

use Test::More tests => 2;

use WebService::Pandora::Cryptor;

my $cryptor = WebService::Pandora::Cryptor->new( encryption_key => 'mycryptkey',
                                                 decryption_key => 'mycryptkey' );

my $data = "encryptmeplz";

my $encrypted = $cryptor->encrypt( $data );
is( $encrypted, '68d61496323a99c737a3c9a28d704c00', 'encrypt' );

my $decrypted = $cryptor->decrypt( $encrypted );
is( $decrypted, 'encryptmeplz', 'decrypt' );