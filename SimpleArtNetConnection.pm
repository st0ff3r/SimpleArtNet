#/usr/bin/perl

# SimpleArtNetConnection.pm
# 
# (C) 2013 Holger Wirtz <dcoredump@googlemail.com>
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free 
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.

package SimpleArtNetConnection;

use IO::Socket::INET;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Data::Dumper;

# flush after every write
$| = 1;

# Init global arrays
sub new
{
	my $class=shift;
	my $self={
		ip=>shift,
		universe=>shift
	};

	bless $self,$class;

	# Init vars
	$self->{'ticks_per_sec'}=25;
	$self->{'_tick'}=1000000.0/$self->{'ticks_per_sec'};
	$self->{'_master_level'}=1.0;

	# Init DMX values
	for($i=0;$i<512;$i++)
	{
		$self->{'_dmx_diff'}[$i]=0.0;
		$self->{'_dmx_step'}[$i]=0.0;
	}
	$self->{'_dmx_channels'}=chr(0)x512;

	# network connection
	$self->{'_socket'}=new IO::Socket::INET (
		PeerAddr=>$self->{'ip'}.":6454",
		Proto=>'udp'
	) || die "ERROR in socket creation : $!\n";

	return($self);
}

sub set
{
	my($self,$channel,$value)=@_;

	$self->fade($channel,$value,0);
}

sub fade
{
	my($self,$channel,$value,$time_sec)=@_;
	my($current_value)=0;

	$current_value=$self->get($channel);

	if($current_value!=$value)
	{
		$self->{'_dmx_step'}[$channel-1]=int($time_sec*$self->{'ticks_per_sec'}+0.5)+1;
		$self->{'_dmx_diff'}[$channel-1]=($value-$current_value)/$self->{'_dmx_step'}[$channel-1];
		print "S:".$channel."=".$self->{'_dmx_step'}[$channel-1]."\n";
		print "D:".$channel."=".$self->{'_dmx_diff'}[$channel-1]."\n\n";
	}
}

sub get
{
	($self,$channel)=@_;

	return(int(vec($self->{'_dmx_channels'},$channel-1,8)));
}

sub blackout_all
{
	($self)=@_;

	$self->{'_dmx_channels'}=chr(0)x512;
}

sub set_ticks
{
        my($self,$tick_per_sec)=@_;

	$self->{'ticks_per_sec'}=$ticks_per_sec;
        $self->{'_tick'}=1000000.0/$self->{'ticks_per_sec'};
}

sub end 
{
	my($self)=@_;

	if($self->{'_socket'})
	{
		$self->{'_socket'}->close();
	}
}

1;
