#! /usr/bin/perl -w

use Data::Dumper;

use lib qw ( /led_controller );
use LedController;

my $movie_file = $ARGV[0];
my $artnet_data_file = $ARGV[1] || "data/artnet.data";
my $slitscan_file = $ARGV[2] || "/var/www/led_controller/images/slitscan.png";

my $c = new LedController;
$c->movie_to_artnet(movie_file => $movie_file, artnet_data_file => $artnet_data_file);
$c->movie_to_slitscan(slitscan_file => $slitscan_file);

1;

__END__
