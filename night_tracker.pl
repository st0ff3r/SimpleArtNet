#! /usr/bin/perl -w

use Config::Simple;
use IPC::ShareLite;
use Proc::Killall;
use Astro::Sunrise;
use DateTime;
use Data::Dumper;

use constant ARTNET_CONF => 'artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);

my $now = DateTime->now(time_zone => 'Europe/Copenhagen');
my $is_dst = $now->is_dst;

my $sunrise_today = sun_rise( { lon => 12.5683, lat => 55.6761, tz => 1, isdst => $is_dst});
print $sunrise_today . "\n";

my $sunset_today = sun_set( { lon => 12.5683, lat => 55.6761, tz => 1, isdst => $is_dst});
print $sunset_today . "\n";

1;

__END__

my $sun = DateTime::Event::Sunrise->new(longitude => +55.6761, latitude => +12.5683);
my $dt = DateTime->now();

my $rise = $sun->sunrise_datetime($dt);
my $set = $sun->sunset_datetime($dt);

$rise->set_time_zone('Europe/Copenhagen');
$set->set_time_zone('Europe/Copenhagen');

print $rise->hms . "\n";
print $set->hms . "\n";
