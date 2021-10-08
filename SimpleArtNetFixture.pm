#/usr/bin/perl

# SimpleArtNetFixture.pm
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

use threads;

package SimpleArtNetFixture;

sub new
{
	my $class=shift;
	my $self={
		connection=>shift,
		name=>shift,
		channel_red=>shift,
		channel_green=>shift,
		channel_blue=>shift,
		channel_control=>shift,
		channel_speed=>shift
	};

	bless $self,$class;

	return($self);
}

sub set_red
{
	($self,$red)=@_;

	$self->{'connection'}->set($self->{'channel_red'},$red);
}

sub set_green
{
	($self,$green)=@_;

	$self->{'connection'}->set($self->{'channel_green'},$green);
}

sub set_blue
{
	($self,$blue)=@_;

	$self->{'connection'}->set($self->{'channel_blue'},$blue);
}

sub set_control
{
	($self,$control)=@_;

	$self->{'connection'}->set($self->{'channel_control'},$control);
}

sub set_speed
{
	($self,$speed)=@_;

	$self->{'connection'}->set($self->{'channel_speed'},$speed);
}

sub set_rgb
{
	($self,$red,$green,$blue)=@_;

	$self->set_red($red);
	$self->set_green($green);
	$self->set_blue($blue);
}

sub fade_rgb
{
	($self,$red,$green,$blue,$time_sec)=@_;

	$self->fade_red($red,$time_sec);
	$self->fade_green($green,$time_sec);
	$self->fade_blue($blue,$time_sec);
}

sub fade_red
{
	($self,$red,$time_sec)=@_;

	$self->{'connection'}->fade($self->{'channel_red'},$red,$time_sec);
}

sub fade_green
{
	($self,$green,$time_sec)=@_;

	$self->{'connection'}->fade($self->{'channel_green'},$green,$time_sec);
}

sub fade_blue
{
	($self,$blue,$time_sec)=@_;

	$self->{'connection'}->fade($self->{'channel_blue'},$blue,$time_sec);
}

sub fade_blue
{
	($self,$blue,$time_sec)=@_;

	$self->{'connection'}->fade($self->{'channel_blue'},$blue,$time_sec);
}

sub get_red
{
	($self)=@_;

	return($self->{'connection'}->get($self->{channel_red}));
}

sub get_green
{
	($self)=@_;

	return($self->{'connection'}->get($self->{channel_green}));
}

sub get_blue
{
	($self)=@_;

	return($self->{'connection'}->get($self->{channel_blue}));
}

sub get_control
{
	($self)=@_;

	return($self->{'connection'}->get($self->{channel_control}));
}

sub get_speed
{
	($self)=@_;

	return($self->{'connection'}->get($self->{channel_speed}));
}

sub blackout_all
{
	($self)=@_;

	$self->{'connection'}->blackout_all();
}

sub blackout
{
	($self)=@_;

	$self->set_red(0);
	$self->set_green(0);
	$self->set_blue(0);
	$self->set_control(0);
	$self->set_speed(0);
}

1;
