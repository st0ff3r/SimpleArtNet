#/bin/sh

cd /led_controller
./send_artnet_data.pl &
./night_tracker.pl

