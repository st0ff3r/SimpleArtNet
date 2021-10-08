#/usr/bin/perl

# SimpleArtNetWorker.pm
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

package SimpleArtNetWorker;

use threads;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Data::Dumper;

# Init global arrays
sub new
{
	my $class=shift;
	my $self={
		connection=>shift
	};

	bless $self,$class;

	# Init thread
	$self->{'_thread'}=threads->create(\&worker_thread,\$self->{'connection'});

	return($self);
}

sub worker_thread
{
	my($super)=@_;

	my($t0)=0;
	my($t1)=0;
	my($s)=0;
	my($i,$v);

	# send blackout 
	$data="Art-Net\x00\x00\x50\000\016\x00\x01".chr($$super->{'universe'})."\x00".chr(255).chr(1).$$super->{'_dmx_channels'};
	$$super->{'_socket'}->send($data);

	while(1)
	{
		$t0=[gettimeofday];
		# The main working part is here!
		for($i=0;$i<512;$i++)
		{
			if($$super->{'_dmx_step'}[$i]>0)
			{
print "$i: ".$$super->{'_dmx_step'}[$i]."\n";
				$v=int(vec($$super->{'_dmx_channels'},$i,8))+int($$super->{'_dmx_diff'}[$i]);
				if($v<0)
				{
					$v=0;
				}
				elsif($v>255)
				{
					$v=255;
				}
				vec($$super->{'_dmx_channels'},$i,8)=$v;
				$$super->{'_dmx_step'}[$i]--;
			}
		}	
		$data="Art-Net\x00\x00\x50\000\016\x00\x01".chr($$super->{'universe'})."\x00".chr(255).chr(1).$$super->{'_dmx_channels'};
		$$super->{'_socket'}->send($data);

		$t1 = [gettimeofday];

		$t0_t1 = tv_interval $t0, $t1;
		$s=$$super->{'_tick'}-$t0_t1;

		if($s<0.0)
		{
			printf STDERR "Underrun error: %2.8f\n",$s;
		}
		else
		{
			usleep($s);
		}
	}
}

1;
