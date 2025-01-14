all: build up

build:
	docker build -t led_controller:latest .

up:
	docker run --name led_controller -dit -v $$PWD/persistent_data/artnet:/led_controller/data -v $$PWD/persistent_data/images:/var/www/led_controller/images -p 80:80 -p 6454:6454/udp --net=host --restart unless-stopped led_controller:latest

down:
	docker rm $$(docker stop $$(docker ps -a -q --filter ancestor=led_controller:latest --format="{{.ID}}"))

logs:
	docker logs -f led_controller

sh:
	docker exec -it led_controller /bin/bash

