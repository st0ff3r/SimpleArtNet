#! /usr/bin/perl -w

use IO::Socket::INET;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Config::Simple;
use IPC::ShareLite;
use Data::Dumper;

use lib qw ( ./ );
use LedController::Artnet;

use constant ARTNET_CONF => '/led_controller/artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);
my $artnet_data_file = $ARGV[0] || "artnet.data";

my $intensity = 1.0;

my $share = IPC::ShareLite->new(
	-key		=> 6454,
	-create		=> 'yes',
	-destroy	=> 'yes'
) or die $!;

$SIG{HUP} = sub { $intensity = $share->fetch };

# network connection
my $a = new LedController::Artnet(
	peer_addr => $config->param('peer_addr'),
	pixel_format => $config->param('pixel_format') || 'GRB',
	num_channels_per_pixel => $config->param('num_channels_per_pixel') || 3
);

my @pixel_line;
my ($red, $green, $blue);
while (1) {
	open(FH, '<', $artnet_data_file) or die $!;
	while(<FH>){
		@pixel_line = (/.{2}/g);
		my $i = 0;
		while (($red, $green, $blue) = splice(@pixel_line, 0, 3)) {
			if ($config->param('num_channels_per_pixel') == 3) {
				$a->set_pixel(
					pixel => $i,
					red => $intensity * hex($red) / 255,
					green => $intensity * hex($green) / 255,
					blue => $intensity * hex($blue) / 255,
				);
			}
			elsif ($config->param('num_channels_per_pixel') == 4) {
				@_ = sort {$a <=> $b} (hex($red), hex($green), hex($blue));
				my $white = $intensity * $_[0] / 255;
				$a->set_pixel(
					pixel => $i,
					red => $intensity * hex($red) / 255 - $white,
					green => $intensity * hex($green) / 255 - $white,
					blue => $intensity * hex($blue) / 255 - $white,
					white => $white
				);
			}
			$i++;
		}
		$a->send_artnet();
		usleep($config->param('speed'));
	}
	close(FH);
}

1;

__END__
