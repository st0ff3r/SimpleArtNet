#! /usr/bin/perl -w

use Config::Simple;
use IPC::ShareLite;
use Data::Dumper;

use constant ARTNET_CONF => 'artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);

my $intensity = $ARGV[0];
my $pid = $ARGV[1] || die "need pid of send_artnet_data process\n";

my $share = IPC::ShareLite->new(
	-key		=> 6454,
	-create		=> 'yes',
	-destroy	=> 'no'
) or die $!;

$share->store($intensity);
kill('HUP', $pid);
