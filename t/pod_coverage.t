use Test::More;
use Test::Pod::Coverage;

pod_coverage_ok( 'WebService::Pandora' );
pod_coverage_ok( 'WebService::Pandora::Cryptor' );
pod_coverage_ok( 'WebService::Pandora::Method' );

# only worry about parent Partner module and not sub-classes
my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };
pod_coverage_ok( 'WebService::Pandora::Partner', $trustparents );

done_testing();