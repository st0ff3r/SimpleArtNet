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
	warn Dumper $progress;
	if ($progress ne "") {
		print("data: " . ceil($progress) . "\n\n");
	}
	else {
		print("data: TERMINATE\n\n");
		exit;
	}
}