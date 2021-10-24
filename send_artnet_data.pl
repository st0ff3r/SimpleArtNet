#! /usr/bin/perl -w

use IO::Socket::INET;
use Config::Simple;
use IPC::ShareLite;
use Data::Dumper;

use lib qw ( ./ );
use LedController::Artnet;

use constant ARTNET_CONF => '/led_controller/artnet.conf';
use constant CROSS_FADE_TIME => 0.01;

my $config = new Config::Simple(ARTNET_CONF);
my $artnet_data_file = $ARGV[0] || "data/artnet.data";
my $artnet_data = '';
my $new_artnet_data = '';

my $intensity = 1.0;
my $cross_fade_intensity = 0.0;
my $cross_fade_state = 'fade_in';
my $artnet_data_file_fh;

my $share_intensity = IPC::ShareLite->new(
	-key		=> 6454,
	-create		=> 'yes',
	-destroy	=> 'yes'
) or die $!;

$SIG{HUP} = sub { $intensity = $share_intensity->fetch };
$SIG{USR1} = sub {
	$cross_fade_state = 'fade_out';
	
	warn "fading to new data\n";
	open($artnet_data_file_fh, '<', $artnet_data_file) or warn $!;
	$new_artnet_data = do { local $/; <$artnet_data_file_fh> };	# read all data into memory
	close $artnet_data_file_fh;
};

# network connection
my $artnet = new LedController::Artnet(
	peer_addr => $config->param('peer_addr'),
	pixel_format => $config->param('pixel_format') || 'GRBW',
	num_channels_per_pixel => $config->param('num_channels_per_pixel') || 4,
	num_pixels => $config->param('num_pixels') || 300
);

my @pixel_line;
my ($red, $green, $blue);
open($artnet_data_file_fh, '<', $artnet_data_file) or warn $!;
$artnet_data = do { local $/; <$artnet_data_file_fh> };	# read all data into memory
close $artnet_data_file_fh;
while (1) {
	foreach (split("\n", $artnet_data)) {
		@pixel_line = (/.{2}/g);
		if ($cross_fade_state eq 'fade_out' && $cross_fade_intensity > 0.0) {
			$cross_fade_intensity -= CROSS_FADE_TIME;	# 1000 steps
			warn "fading out, intensity: " . $cross_fade_intensity;
		}
		elsif ($cross_fade_state eq 'fade_out' && $cross_fade_intensity <= 0) {
			$cross_fade_intensity = 0.0;
			$cross_fade_state = 'off';
			# switch to new data
			$artnet_data = $new_artnet_data;
			$cross_fade_state = 'fade_in';
		}
		elsif ($cross_fade_state eq 'fade_in' && $cross_fade_intensity < 1.0) {
			$cross_fade_intensity += CROSS_FADE_TIME;
			warn "fading in, intensity: " . $cross_fade_intensity;
		}
		elsif ($cross_fade_state eq 'fade_in' && $cross_fade_intensity >= 1.0) {
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
