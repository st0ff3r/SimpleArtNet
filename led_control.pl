#! /usr/bin/perl -w

use Config::Simple;
use IPC::ShareLite;
use Data::Dumper;

use constant ARTNET_CONF => 'artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);

my $intensity = $ARGV[0];

my $share = IPC::ShareLite->new(
	-key		=> 6454,
	-create		=> 'yes',
	-destroy	=> 'yes'
) or die $!;

$share->store($intensity);
