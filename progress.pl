#!/usr/bin/perl

use IPC::ShareLite;
use POSIX qw( ceil );
use Data::Dumper;

$processing_progress = IPC::ShareLite->new(
	-key		=> 6455,
	-create		=> 'yes',
	-destroy	=> 'no'
) or die $!;

my $progress = $processing_progress->fetch;
if ($progress ne "") {
	print("data: " . ceil($progress) . "\n\n");
}
else {
	print("data: TERMINATE\n\n");
}
