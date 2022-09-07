#! /usr/bin/perl -w

use strict;
use Config::Simple;
use IPC::ShareLite;
use Time::HiRes qw(usleep gettimeofday tv_interval);
#use Redis;
#use Storable qw(freeze thaw);
use IO::Socket::INET;
use Data::Dumper;

use constant ARTNET_CONF => 'artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);

my $socket = new IO::Socket::INET (
	LocalAddr	=> 'localhost',
	LocalPort	=> '6454',
	Proto		=> 'udp'
) || die "ERROR in socket creation : $!\n";

my (
	$opcode_h,
	$opcode_l,
	$protocol_version_h,
	$protocol_version_l,
	$sequence,
	$physical,
	$universe_h,
	$universe_l,
	$length_h,
	$length_l
);
my $length;
my $dmx;

while (1) {
	my $recieved_data;
	$socket->recv($recieved_data, 1024);
	$opcode_h = vec($recieved_data, 8, 8);
	$opcode_l = vec($recieved_data, 9, 8);
	
	$protocol_version_h = vec($recieved_data, 10, 8);
	$protocol_version_l = vec($recieved_data, 11, 8);

	$sequence = vec($recieved_data, 12, 8);
	$physical = vec($recieved_data, 13, 8);

	$universe_h = vec($recieved_data, 14, 8);
	$universe_l = vec($recieved_data, 15, 8);

	$length_h = vec($recieved_data, 16, 8);
	$length_l = vec($recieved_data, 17, 8);

	$length = $length_h << 8 + $length_l;
	if ($length <= 512) {
		$dmx = vec($recieved_data, 18, 8);
		set_intensity(int($dmx / 255));
#		for (0..$length) {
#			$dmx = vec($recieved_data, 18 + $_, 8);
#			printf("0x%x ", $dmx);
#		}
	}
#	print "\n\n";
}

$socket->close();



sub set_intensity {
	my $intensity = shift;
	
#	warn "intensity: $intensity\n";

	my $share = IPC::ShareLite->new(
		-key		=> 6455,
		-create		=> 'yes',
		-destroy	=> 'no'
	) or die $!;

	$share->store($intensity);
	killall('USR1', 'send_artnet_data');
}

1;

__END__