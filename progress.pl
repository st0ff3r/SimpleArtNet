#!/usr/bin/perl

use IPC::ShareLite;
use POSIX qw( ceil );
use Apache2::RequestUtil;
use Apache2::Const;
use CGI;
use CGI::Cookie ();
use Data::Dumper;

use constant REDIS_HOST => '127.0.0.1';
use constant REDIS_PORT => '6379';

my $redis_host = REDIS_HOST;
my $redis_port = REDIS_PORT;
my $redis = Redis->new(
	server => "$redis_host:$redis_port",
) || warn $!;

my $r = Apache2::RequestUtil->request;

my %cookies = ();
my $session_id = '';
if (%cookies = CGI::Cookie->fetch) {
	# cookie received
	$session_id = $cookies{'session_id'}->value;

	# send it again
	my $cookie = CGI::Cookie->new(-name  => 'session_id', -value => $session_id);
	$r->err_headers_out->add('Set-Cookie' => $cookie);
}

print "Content-type: text/event-stream\n";
print "Cache-Control: no-cache\n";
print "Connection: keep-alive\n\n";

while (1) {
	my $progress = $redis->get('progress:' . $session_id);
	if ($progress < 0) {
		print("data: ERROR\n\n");
		$redis->set('progress:' . $session_id, '0.0');
		exit;
	}
	elsif ($progress == 100) {
		print("data: 100\n\n");
		print("data: TERMINATE\n\n");
		$redis->set('progress:' . $session_id, '0.0');
		exit;
	}
	else {
		print("data: " . ceil($progress) . "\n\n");
	}
}