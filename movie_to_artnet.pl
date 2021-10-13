#! /usr/bin/perl -w

use Data::Dumper;

use lib qw ( /led_controller );
use LedController;

use constant ARTNET_CONF => '/led_controller/artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);

my $movie_file = $ARGV[0];
my $artnet_data_file = $ARGV[1] || "artnet.data";

my $c = new LedController;
$c->movie_to_artnet(movie_file => $movie_file, artnet_data_file => $artnet_data_file);

1;

__END__
