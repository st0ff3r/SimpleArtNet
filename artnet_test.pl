#! /usr/bin/perl -w

use Artnet;
use IO::Socket::INET;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Data::Dumper;

use constant PEER_ADDR => '192.168.6.18';
#use constant PEER_ADDR => '127.0.0.1';
use constant UNIVERSE => 0;

use constant SPEED => 20_000;

# network connection
my $a = new Artnet(
	peer_addr => PEER_ADDR
);

my $dir = 0;
my $i = 0;
while (1) {
	for (1..30) {
		$a->set_pixel(
			pixel => $_ - 1,
			red => 1.0 * $i / 255,
			green => 0.4 * $i / 255,
			blue => 0.2 * $i / 255
		);
	}
	
	$a->send_artnet();
	if ($dir == 0) {
		if ($i < 255) {
			$i++;
		}
		else {
			$dir = 1;
		}
	}
	else {
		if ($i > 0) {
			$i--;
		}
		else {
			$dir = 0;
		}
	}

	# compensate for non linearity
	if ($i < 30) {
		usleep(SPEED * 2);
	}
	else {
		usleep(SPEED);
	}
}

1;

__END__
