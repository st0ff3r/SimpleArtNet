#! /usr/bin/perl -w

use IO::Socket::INET;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Config::Simple;
use Data::Dumper;

use lib qw ( ./ );
use Artnet;

use constant ARTNET_CONF => 'artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);
my $artnet_data_file = $ARGV[0];

# network connection
my $a = new Artnet(
	peer_addr => $config->param('peer_addr')
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
		usleep($config->param('speed'));
	}
	close(FH);
}

1;

__END__
