#! /usr/bin/perl -w

use IO::Socket::INET;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Data::Dumper;

use lib qw ( ./ );
use Artnet;

use constant PEER_ADDR => '192.168.6.18';
#use constant PEER_ADDR => '127.0.0.1';
use constant UNIVERSE => 0;

use constant SPEED => 40_000;

my $artnet_data_file = $ARGV[0];

# network connection
my $a = new Artnet(
	peer_addr => PEER_ADDR
);

my @pixel_line;
my ($red, $green, $blue);
while (1) {
	open(FH, '<', $artnet_data_file) or die $!;
	while(<FH>){
		@pixel_line = (/.{2}/g);
		my $i = 0;
		while (($red, $green, $blue) = splice(@pixel_line, 0, 3)) {
			$a->set_pixel(
				pixel => $i,
				red => hex($red) / 255,
				green => hex($green) / 255,
				blue => hex($blue) / 255,
			);
			$i++;
		}
		$a->send_artnet();
		usleep(SPEED);
	}
	close(FH);
}

1;

__END__
