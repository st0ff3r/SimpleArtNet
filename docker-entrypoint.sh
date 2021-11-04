#!/bin/bash

service apache2 start
service redis-server start

#chown -R www-data:www-data /led_controller/data
cd /led_controller

terminate() {
	echo "sending SIGTERM to child processes"
	kill -TERM "$send_artnet_data_pid" 2> /dev/null
	sleep 5;
	kill -TERM "$artnetd_pid" 2> /dev/null
}

trap terminate SIGTERM

./sun_tracker.pl &
sleep 5;

#sudo -u www-data 
./artnetd.pl &
artnetd_pid=$!

#sudo -u www-data 
./send_artnet_data.pl &
send_artnet_data_pid=$!

wait "$send_artnet_data_pid"
wait "$artnetd_pid"
