#!/usr/bin/perl

use IPC::ShareLite;
use POSIX qw( ceil );
use Data::Dumper;

my $processing_progress = IPC::ShareLite->new(
	-key		=> 6455,
	-create		=> 'yes',
	-destroy	=> 'no'
) or die $!;

print "Content-type: text/event-stream\n";
print "Cache-Control: no-cache\n";
print "Connection: keep-alive\n\n";

while (1) {
	my $progress = $processing_progress->fetch;
	if ($progress < 0) {
		print("data: ERROR\n\n");
		$processing_progress->store(0.0);
		exit;
	}
	elsif ($progress == 100) {
		print("data: 100\n\n");
		print("data: TERMINATE\n\n");
		$processing_progress->store(0.0);
		exit;
	}
	else {
		print("data: " . ceil($progress) . "\n\n");
	}
}