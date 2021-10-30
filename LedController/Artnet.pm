package LedController::Artnet;

use strict;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use POSIX qw( ceil );
use Data::Dumper;
use Redis;
use Data::HexDump;

use constant REDIS_HOST => '127.0.0.1';
use constant REDIS_PORT => '6379';
use constant REDIS_QUEUE_NAME => 'artnet';

use constant BUFFER_TIME => 5;

my @gamma_table = (
	0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,
	1,  1,  1,  1,  1,  1,  1,  1,  1,  2,  2,  2,  2,  2,  2,  2,
	2,  3,  3,  3,  3,  3,  3,  3,  4,  4,  4,  4,  4,  5,  5,  5,
	5,  6,  6,  6,  6,  7,  7,  7,  7,  8,  8,  8,  9,  9,  9, 10,
	10, 10, 11, 11, 11, 12, 12, 13, 13, 13, 14, 14, 15, 15, 16, 16,
	17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 23, 24, 24, 25,
	25, 26, 27, 27, 28, 29, 29, 30, 31, 32, 32, 33, 34, 35, 35, 36,
	37, 38, 39, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 50,
	51, 52, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 66, 67, 68,
	69, 70, 72, 73, 74, 75, 77, 78, 79, 81, 82, 83, 85, 86, 87, 89,
	90, 92, 93, 95, 96, 98, 99,101,102,104,105,107,109,110,112,114,
	115,117,119,120,122,124,126,127,129,131,133,135,137,138,140,142,
	144,146,148,150,152,154,156,158,160,162,164,167,169,171,173,175,
	177,180,182,184,186,189,191,193,196,198,200,203,205,208,210,213,
	215,218,220,223,225,228,231,233,236,239,241,244,247,249,252,255
);

sub new {
	my $class = shift;
	my %p = @_;
	my $self = {};

	$self->{num_channels_per_pixel} = $p{num_channels_per_pixel};
	$self->{pixel_format} = $p{pixel_format};
	$self->{num_pixels} = $p{num_pixels};

	my $redis_host = REDIS_HOST;
	my $redis_port = REDIS_PORT;
	$self->{redis} = Redis->new(
		server => "$redis_host:$redis_port",
	) || warn $!;

	my $queue_name = 'artnet';

	$self->{num_universes} = ceil($self->{num_pixels} * $self->{num_channels_per_pixel} / 512);
	for (1..$self->{num_universes}) {
		$self->{dmx_channels}[$_ - 1] = chr(0) x 512;
	}
	
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
	my $white = 0;
		
	# do gamma correction
	$red = gamma_correction($red);
	$green = gamma_correction($green);
	$blue = gamma_correction($blue);
	
	if ($self->{num_channels_per_pixel} == 4) {
		# convert from rgb to rgbw
		@_ = sort {$a <=> $b} ($red, $green, $blue);
		$white = $_[0];
		$red -= $white;
		$green -= $white;
		$blue -= $white;
	}
	
	my $channel = ($pixel * $self->{num_channels_per_pixel}) % 512;
	my $universe = int($pixel * $self->{num_channels_per_pixel} / 512);
#	print('pixel: ' . $pixel . ' => ' . 'universe: ' . $universe . ', channel: ' . $channel . "\n");
	if ($self->{pixel_format} eq 'GRB') {
		vec($self->{dmx_channels}[$universe], $channel + 0, 8) = $green;
		vec($self->{dmx_channels}[$universe], $channel + 1, 8) = $red;
		vec($self->{dmx_channels}[$universe], $channel + 2, 8) = $blue;
	}
	elsif ($self->{pixel_format} eq 'GRBW') {
		vec($self->{dmx_channels}[$universe], $channel + 0, 8) = $green;
		vec($self->{dmx_channels}[$universe], $channel + 1, 8) = $red;
		vec($self->{dmx_channels}[$universe], $channel + 2, 8) = $blue;
		vec($self->{dmx_channels}[$universe], $channel + 3, 8) = $white;
	}
}

sub send_artnet {
	my $self = shift;
	my %p = @_;

	my $packet;
	for (1..$self->{num_universes}) {
		$packet = "Art-Net\x00\x00\x50\x00\x0e\x00\x00" . chr($_ - 1) . "\x00" . chr(2) . chr(0) . $self->{dmx_channels}[$_ - 1];
		$self->add_artnet_to_queue(artnet => $packet, fps => $p{fps});
	}
#	for (1..$self->{num_universes}) {
#		$packet = "Art-Net\x00\x00\x50\x00\x0e\x00\x00" . chr($_ - 1 + 3) . "\x00" . chr(2) . chr(0) . $self->{dmx_channels}[$_ - 1];
#		$self->add_artnet_to_queue(artnet => $packet, fps => $p{fps});
#	}
	# wait for buffer to be emptied
	while ($self->{redis}->keys('artnet:*') > (BUFFER_TIME * $p{fps})) {
		usleep 1000_000 * BUFFER_TIME / 2;
	}
}

# private functions
sub gamma_correction {
	return $gamma_table[shift];
}

sub add_artnet_to_queue {
	my $self = shift;
	my %p = @_;

	# Create the next id
	my $id = $self->{redis}->incr(join(':', REDIS_QUEUE_NAME, 'id'));
	my $job_id = join(':', REDIS_QUEUE_NAME, $id);

	my %data = (topic => 'artnet', message => $p{artnet});

	# Set the data first
	$self->{redis}->hmset($job_id, %data);

	# Then add the job to the queue
	$self->{redis}->rpush(join(':', REDIS_QUEUE_NAME, 'queue'), $job_id);
	
	$self->{redis}->set('fps', $p{fps});
}

1;

__END__
