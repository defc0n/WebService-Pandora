package WebService::Pandora::Partner::WindowsGadget;

use strict;
use warnings;

use base 'WebService::Pandora::Partner';

sub new {

    my $caller = shift;

    my $class = ref( $caller );
    $class = $caller if ( !$class );

    my $self = $class->SUPER::new( username => 'windowsgadget',
				   password => 'EVCCIBGS9AOJTSYMNNFUML07VLH8JYP0',
				   device_id => 'WG01',
				   decryption_key => 'E#IO$MYZOAB%FVR2',
				   encryption_key => '%22CML*ZU$8YXP[1',
				   host => 'internal-tuner.pandora.com' );
    
    return $self;
}

1;
