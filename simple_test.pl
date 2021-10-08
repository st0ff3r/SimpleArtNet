#!/usr/bin/perl


use SimpleArtNetWorker;
use SimpleArtNetConnection;
use SimpleArtNetFixture;
use threads;

$c=new SimpleArtNetConnection("127.0.0.1",0);
$w=new SimpleArtNetWorker($c);
$s=new SimpleArtNetFixture($c,"Spot",2,3,4,1,5);

sleep(3);
print "START\n";
$s->set_rgb(255,0,0);
sleep(2);
$s->set_rgb(0,255,0);
sleep(2);
$s->set_rgb(0,0,255);
sleep(2);
$s->fade_blue(128,5.5);
sleep(5);
$s->blackout();
sleep(5);
$c->end();
