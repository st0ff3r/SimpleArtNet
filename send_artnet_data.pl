#! /usr/bin/perl -w

use IO::Socket::INET;
use Config::Simple;
use IPC::ShareLite;
use Data::Dumper;

use lib qw ( ./ );
use LedController::Artnet;

use constant ARTNET_CONF => '/led_controller/artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);
my $artnet_data_file = $ARGV[0] || "data/artnet.data";
my $artnet_data = '';
my $new_artnet_data = '';

my $intensity = 1.0;
my $cross_fade_intensity = 0.0;
my $cross_fade_state = 'fade_in';

my $cross_fade_time = $config->param('cross_fade_time') || 2;
my $cross_fade_per_step = 1 / ($cross_fade_time * $config->param('fps')) / 2;

my $share_intensity = IPC::ShareLite->new(
	-key		=> 6454,
	-create		=> 'yes',
	-destroy	=> 'yes'
) or die $!;

$SIG{USR1} = sub { $intensity = $share_intensity->fetch };
$SIG{USR2} = sub {
	$cross_fade_state = 'fade_out';
	
	warn "fading to new data\n";
	open(FH, '<', $artnet_data_file) or warn $!;
	$new_artnet_data = do { local $/; <FH> };	# read all data into memory
	close FH;
};

my $should_exit = 0;
$SIG{HUP} = sub { $cross_fade_state = 'fade_out'; $should_exit = 1 };
$SIG{INT} = sub { $cross_fade_state = 'fade_out'; $should_exit = 1 };

# network connection
my $artnet = new LedController::Artnet(
	peer_addr => $config->param('peer_addr'),
	pixel_format => $config->param('pixel_format') || 'GRBW',
	num_channels_per_pixel => $config->param('num_channels_per_pixel') || 4,
	num_pixels => $config->param('num_pixels') || 300
);

my @pixel_line;
my ($red, $green, $blue);
open(FH, '<', $artnet_data_file) or warn $!;
$artnet_data = do { local $/; <FH> };	# read all data into memory
close FH;
while (1) {
	foreach (split("\n", $artnet_data)) {
		@pixel_line = (/.{2}/g);
		if ($cross_fade_state eq 'fade_out' && $cross_fade_intensity > 0.0) {
			$cross_fade_intensity -= $cross_fade_per_step;	# 1000 steps
		}
		elsif ($cross_fade_state eq 'fade_out' && $cross_fade_intensity <= 0) {
			warn "faded out\n";
			$cross_fade_intensity = 0.0;
			$cross_fade_state = 'off';
			if ($should_exit) {
				die "quitting\n";
			}
			else {
				# switch to new data
				$artnet_data = $new_artnet_data;
				$cross_fade_state = 'fade_in';
				last;
			}
		}
		elsif ($cross_fade_state eq 'fade_in' && $cross_fade_intensity < 1.0) {
			$cross_fade_intensity += $cross_fade_per_step;
		}
		elsif ($cross_fade_state eq 'fade_in' && $cross_fade_intensity >= 1.0) {
			warn "faded in\n";
			$cross_fade_intensity = 1.0;
			$cross_fade_state = 'on';
		}
		my $i = 0;
		while (($red, $green, $blue) = splice(@pixel_line, 0, 3)) {
			$artnet->set_pixel(
				pixel => $i,
				red => $intensity * hex($red) * $cross_fade_intensity,
				green => $intensity * hex($green) * $cross_fade_intensity,
				blue => $intensity * hex($blue) * $cross_fade_intensity
			);
			$i++;
		}
		$artnet->send_artnet(fps => $config->param('fps'));
	}
}

END {

}

1;

__END__
