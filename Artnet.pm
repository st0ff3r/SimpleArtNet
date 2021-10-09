package Artnet;

use Data::Dumper;

use constant NUM_CHANNELS_PER_PIXEL => 3;
use constant PIXEL_FORMAT => 'GRB';

# flush after every write
$| = 1;

sub new {
	my $class = shift;
	my %p = @_;
	my $self = {};

	# network connection
	$self->{socket} = new IO::Socket::INET (
		PeerAddr	=> $p{peer_addr} . ":6454",
		Proto		=> 'udp'
	) || die "ERROR in socket creation : $!\n";

	$self->{dmx_channels} = chr(0) x 512;
	$self->{universe} = 0;

	bless $self, $class;

	return($self);
}

sub set_pixel {
	my $self = shift;
	my %p = @_;
	
	my $pixel = $p{pixel};
	my $red = $p{red};
	my $green = $p{green};
	my $blue = $p{blue};
	
	if ($pixel * NUM_CHANNELS_PER_PIXEL <= 512) {
		if (PIXEL_FORMAT eq 'GRB') {
			vec($self->{dmx_channels}, $pixel * NUM_CHANNELS_PER_PIXEL + 0, 8) = int(0xff * $green);
			vec($self->{dmx_channels}, $pixel * NUM_CHANNELS_PER_PIXEL + 1, 8) = int(0xff * $red);
			vec($self->{dmx_channels}, $pixel * NUM_CHANNELS_PER_PIXEL + 2, 8) = int(0xff * $blue);
		}
	}
}

sub send_artnet {
	my ($self) = @_;

	my $packet = "Art-Net\x00\x00\x50\x00\x0e\x00\x00" . chr($self->{universe}) . "\x00" . chr(2) . chr(0) . $self->{dmx_channels};
	$self->{socket}->send($packet);
}

1;

__END__
