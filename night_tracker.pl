#! /usr/bin/perl -w

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
	my $sun_start = DateTime::Event::Sunrise->new(longitude => 12.5683, latitude => 55.6761, altitude => -6);
	my $sun_end = DateTime::Event::Sunrise->new(longitude => 12.5683, latitude => 55.6761, altitude => -0.833);
	
	my $dt = DateTime->now(time_zone => 'Europe/Copenhagen');
	#my $is_dst = $dt->is_dst;
	
	my $rise_start = $sun_start->sunrise_datetime($dt);
	my $rise_end = $sun_end->sunrise_datetime($dt);
	my $set_start = $sun_end->sunset_datetime($dt);
	my $set_end = $sun_start->sunset_datetime($dt);
	
	my $dur_rise = new DateTime::Duration;
	my $dur_set = new DateTime::Duration;
	$dur_rise = $rise_end - $rise_start;
	print "rise: " . $rise_start->hms . "-" . $rise_end->hms . ", " . $dur_rise->minutes . " minutes\n";
	
	$dur_set = ($set_end - $set_start);
	print "set: " . $set_start->hms . "-" . $set_end->hms . ", " . $dur_set->minutes . " minutes\n";
	
	if ($rise_start < $dt && $dt < $rise_end) {
		warn "rising\n";
		my $dur = new DateTime::Duration;
		$dur = $dt - $rise_start;
		set_intensity($dur->minutes * (1 / $dur_rise->minutes));
	}
	elsif ($rise_end < $dt && $dt < $set_start) {
		warn "up\n";
		set_intensity(1.0);
	}
	elsif ($set_start < $dt && $dt < $set_end) {
		warn "setting\n";
		my $dur = new DateTime::Duration;
		$dur = $dt - $set_start;
		set_intensity(1 - ($dur->minutes * (1 / $dur_set->minutes)));
	}
	elsif ($set_end < $dt && $dt < $rise_start) {
		warn "down\n";
		set_intensity(0.0);
	}
	
	sleep 60;
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
