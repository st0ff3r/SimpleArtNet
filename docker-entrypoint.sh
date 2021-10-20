#/bin/sh

service apache2 start

chown -R www-data:www-data /led_controller/data
cd /led_controller
./send_artnet_data.pl &
./sun_tracker.pl
