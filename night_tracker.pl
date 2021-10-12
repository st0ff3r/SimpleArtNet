#! /usr/bin/perl -w

use strict;
use Config::Simple;
use IPC::ShareLite;
use Proc::Killall;
use DateTime;
use DateTime::Event::Sunrise;
use DateTime::Duration;
use IPC::ShareLite;
use Proc::Killall;
use Data::Dumper;

use constant ARTNET_CONF => 'artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);

while (1) {
	my $sunrise_start = DateTime::Event::Sunrise->sunrise(longitude => 12.5683, latitude => 55.6761, altitude => -6);
	my $sunrise_end = DateTime::Event::Sunrise->sunrise(longitude => 12.5683, latitude => 55.6761, altitude => -0.833);
	my $sunset_start = DateTime::Event::Sunrise->sunset(longitude => 12.5683, latitude => 55.6761, altitude => -0.833);
	my $sunset_end = DateTime::Event::Sunrise->sunset(longitude => 12.5683, latitude => 55.6761, altitude => -6);
	
	my $dt_now = DateTime->now(time_zone => 'Europe/Copenhagen');
	my $dt_today = $dt_now->clone;
	$dt_today->subtract(hours => 6);
	
	my $dt_rise_start = $sunrise_start->next($dt_today);
	my $dt_rise_end = $sunrise_end->next($dt_today);
	my $dt_set_start = $sunset_start->next($dt_today);
	my $dt_set_end = $sunset_end->next($dt_today);

	my $now = $dt_now->epoch;

	my $rise_start = $dt_rise_start->epoch;
	my $rise_end = $dt_rise_end->epoch;
	my $set_start = $dt_set_start->epoch;
	my $set_end = $dt_set_end->epoch;
	
	my $dur_rise = $rise_end - $rise_start;
	my $dur_set = $set_end - $set_start;
	
	warn "now:" . $dt_now . " rise:" . $dt_rise_start . " - " . $dt_rise_end . ", set:" . $dt_set_start . " - " . $dt_set_end . "\n";
	if ($rise_start <= $now && $now < $rise_end) {
		warn "rising\n";
		warn "rise: " . $dt_rise_start->hms . "-" . $dt_rise_end->hms . ", " . $dur_rise . " seconds\n";
		my $dur = $now - $rise_start;
		set_intensity(1 - ($dur * (1 / $dur_rise)));
	}
	elsif ($rise_end <= $now && $now < $set_start) {
		warn "up\n";
		set_intensity(0.0);
	}
	elsif ($set_start <= $now && $now < $set_end) {
		warn "setting\n";
		warn "set: " . $dt_set_start->hms . "-" . $dt_set_end->hms . ", " . $dur_set . " seconds\n";
		my $dur = $now - $set_start;
		set_intensity($dur * (1 / $dur_set));
	}
	elsif ($set_end <= $now && $now < $rise_start) {
		warn "down\n";
		set_intensity(1.0);
	}
	
	sleep 1;
}

sub set_intensity {
	my $intensity = shift;
	
	warn "intensity: $intensity\n";

	my $share = IPC::ShareLite->new(
		-key		=> 6454,
		-create		=> 'yes',
		-destroy	=> 'no'
	) or die $!;

	$share->store($intensity);
	killall('HUP', 'send_artnet_data');
}

1;

__END__
