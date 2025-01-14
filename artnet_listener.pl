#! /usr/bin/perl -w

use strict;
use Config::Simple;
use IPC::ShareLite;
use Proc::Killall;
use Time::HiRes qw(usleep gettimeofday tv_interval);
#use Redis;
#use Storable qw(freeze thaw);
use IO::Socket::INET;
use Sys::Hostname;
use threads;
use threads::shared;
use Data::Dumper;

use constant ARTNET_CONF => 'artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);
my $artnet_listener_timeout = $config->param('artnet_listener_timeout') || 10;

my $socket = new IO::Socket::INET (
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
my $opcode;
my $universe;
my $dmx;

my $last_received_time :shared = time();

set_intensity(1.0);

sub artnet_watchdog_thread {
	while (1) {
#		print "$last_received_time\n";
		if ($last_received_time + $artnet_listener_timeout < time()) {
			print "ArtNet timeout\n";
			set_intensity(1.0);
		}
		usleep(1000_000);
	}
}
my $thread = threads->create(\&artnet_watchdog_thread);

while (1) {
	my $recieved_data;
	$socket->recv($recieved_data, 1024);
	$last_received_time = time();

	$opcode_l = vec($recieved_data, 8, 8);
	$opcode_h = vec($recieved_data, 9, 8);
	
	$protocol_version_h = vec($recieved_data, 10, 8);
	$protocol_version_l = vec($recieved_data, 11, 8);

	$sequence = vec($recieved_data, 12, 8);
	$physical = vec($recieved_data, 13, 8);

	$universe_h = vec($recieved_data, 14, 8);
	$universe_l = vec($recieved_data, 15, 8);

	$length_h = vec($recieved_data, 16, 8);
	$length_l = vec($recieved_data, 17, 8);

	$opcode = $opcode_h << 8 + $opcode_l;
	$length = $length_h << 8 + $length_l;
	$universe = $universe_h << 8 + $universe_l;

	if ($opcode == 0x5000) {	# ArtNet packet
		if ($length <= 512) {	# sanity check
			if ($universe == $config->param('my_universe')) {
				$dmx = vec($recieved_data, 18, 8);
#				printf("dmx: %0x\n", $dmx);
				set_intensity($dmx / 255);
#				for (0..$length) {
#					$dmx = vec($recieved_data, 18 + $_, 8);
#					printf("0x%x ", $dmx);
#				}
#				print "\n\n";
			}
		}
	}
	elsif ($opcode == 0x2000) {	# ArtPoll packet
		my $peer_ip = $socket->peerhost;
		my $socket_reply = new IO::Socket::INET (
			PeerAddr	=> $peer_ip . ":6454",
			Proto		=> 'udp'
		) || warn "ERROR in socket creation : $!\n";

		my $host_ip = $socket_reply->sockhost;
		my $packet = "Art-Net\x00\x00\x21" . join('', map({chr $_} split(/\./, $host_ip))) . "\x36\x19" . 
			"\x04\x20".
			"\x00\x00" .
			"\xff\xff" .
			"\x00" .
			"\xf0" .
			"\xff\xff" .
			"Trappe LED" . "\x00" x 8 .
			"Trappe LED" . "\x00" x 54 .
			"\x00" x 64 .
			"\x00\x01" .
			"\x80\x80\x80\x80" .
			"\x00" x 35;

		$socket_reply->send($packet);
		$socket_reply->close();
	}
#	print "\n\n";
}
$socket->close();
$thread->join();

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