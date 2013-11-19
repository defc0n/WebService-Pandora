use Test::More tests => 1;
use WebService::Pandora;

my $websvc = WebService::Pandora->new();

ok( defined( $websvc ), "object instantiated" );