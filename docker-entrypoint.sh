#/bin/sh

service apache2 start

cd /led_controller
./send_artnet_data.pl &
./sun_tracker.pl
