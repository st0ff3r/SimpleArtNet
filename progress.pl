#!/usr/bin/perl

use IPC::ShareLite;
use POSIX qw( ceil );
#use Apache2::RequestUtil;
#use Apache2::Const;
use Data::Dumper;

use constant REDIS_HOST => '127.0.0.1';
use constant REDIS_PORT => '6379';

my $redis_host = REDIS_HOST;
my $redis_port = REDIS_PORT;
$self->{redis} = Redis->new(
	server => "$redis_host:$redis_port",
) || warn $!;

#my $r = Apache2::RequestUtil->request;

print "Content-type: text/event-stream\n";
print "Cache-Control: no-cache\n";
print "Connection: keep-alive\n\n";

while (1) {
	my $progress = $self->{redis}->get('progress');
	if ($progress < 0) {
		print("data: ERROR\n\n");
		$self->{redis}->set('progress', '0.0');
		exit;
	}
	elsif ($progress == 100) {
		print("data: 100\n\n");
		print("data: TERMINATE\n\n");
		$self->{redis}->set('progress', '0.0');
		exit;
	}
	else {
		print("data: " . ceil($progress) . "\n\n");
	}
}