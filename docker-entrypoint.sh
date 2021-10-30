#/bin/sh

service apache2 start
service redis-server start

chown -R www-data:www-data /led_controller/data
cd /led_controller
sudo -u www-data ./artnetd.pl &
sudo -u www-data ./send_artnet_data.pl &
sudo -u www-data ./sun_tracker.pl
