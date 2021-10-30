#! /usr/bin/perl -w

use strict;
use Config::Simple;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Redis;
use IO::Socket::INET;
use Data::Dumper;

use constant REDIS_HOST => '127.0.0.1';
use constant REDIS_PORT => '6379';
use constant REDIS_QUEUE_NAME => 'artnet';

use constant ARTNET_CONF => 'artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);

my $redis_host = REDIS_HOST;
my $redis_port = REDIS_PORT;
my $redis = Redis->new(
	server => "$redis_host:$redis_port",
) || warn $!;

my $queue_name = 'artnet';
my $timeout		= 86400;

# print fps stats
my $stats_start_time = [gettimeofday];
my $stats_frames_played = 0;
$SIG{HUP} = sub { 
	my $avg_fps = $stats_frames_played / tv_interval($stats_start_time);
	print "avg_fps: $avg_fps\n";
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
	my ($queue, $job_id) = $redis->blpop(join(':', $queue_name, 'queue'), $timeout);
	if ($job_id) {
	
		my %data = $redis->hgetall($job_id);
		$socket->send($data{message});

		# remove data for job
		$redis->del($job_id);
	}
	$stats_frames_played++;

	my $usleep_time = 1000_000 * ((1 / $config->param('fps')) - tv_interval($time));
	usleep($usleep_time >= 0 ? $usleep_time : 0);
}

