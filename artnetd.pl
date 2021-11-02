#! /usr/bin/perl -w

use strict;
use Config::Simple;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Redis;
use Storable qw(freeze thaw);
use IO::Socket::INET;
use Data::Dumper;

use constant REDIS_HOST => '127.0.0.1';
use constant REDIS_PORT => '6379';
use constant REDIS_QUEUE_1_NAME => 'artnet_1';
use constant REDIS_QUEUE_2_NAME => 'artnet_2';

use constant ARTNET_CONF => 'artnet.conf';

use constant PID_I => 1000;

my $config = new Config::Simple(ARTNET_CONF);

my $redis_host = REDIS_HOST;
my $redis_port = REDIS_PORT;
my $redis = Redis->new(
	server => "$redis_host:$redis_port",
) || warn $!;

my $timeout = 86400;

my @stats = ();
my $fps_adjustment = 0;
my $avg_fps;
my $fps;

# print fps stats
$SIG{HUP} = sub { 
	if (@stats >= $fps) {
		print "avg_fps: $avg_fps\n";
#		print "fps_adjustment: $fps_adjustment\n";
		print 'PID_I * ($avg_fps - $fps)' . "\n";
		print PID_I . ' * ' . '(' . $avg_fps . ' - ' . $fps . ')' . ' = ' . $fps_adjustment . "\n\n";
	}
	else {
		print "cant calculate stats yet\n";
	}
};

# flush after every write
$| = 1;

# network connection
my $socket = new IO::Socket::INET (
	PeerAddr	=> $config->param('peer_addr') . ":6454",
	Proto		=> 'udp'
) || die "ERROR in socket creation : $!\n";

while (1) {
	my $time = [gettimeofday];
	my ($queue, $job_id);

	($queue, $job_id) = $redis->blpop(join(':', REDIS_QUEUE_1_NAME, 'queue'), $timeout);
	if ($job_id) {
	
		my %data = $redis->hgetall($job_id);
		my $frame = thaw($data{message});
		foreach (@$frame) {
			$socket->send($_);
		}

		# remove data for job
		$redis->del($job_id);
	}
	# for the mirrored data
	($queue, $job_id) = $redis->blpop(join(':', REDIS_QUEUE_2_NAME, 'queue'), $timeout);
	if ($job_id) {
	
		my %data = $redis->hgetall($job_id);
		my $frame = thaw($data{message});
		foreach (@$frame) {
			$socket->send($_);
		}

		# remove data for job
		$redis->del($job_id);
	}
	
	$fps = $redis->get('fps');

	# update fps stats
	if (@stats > $fps * 60) {	# a time window of a minute for stats
		shift @stats;
	}
	push @stats, $time;
	
	# adjust fps (proportionally - debug: should we do I and D too?)
	if (@stats >= $fps) {
		$avg_fps = @stats / tv_interval($stats[0], $stats[-1]);
		$fps_adjustment = PID_I * ($avg_fps - $fps);
	}

	my $usleep_time = 1000_000 * ((1 / $fps) - tv_interval($time)) + $fps_adjustment;
	usleep($usleep_time >= 0 ? $usleep_time : 0);
}

