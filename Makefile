all: build up

build:
	docker build -t led_controller:latest .

up:
	docker run --name led_controller -dit -p 8081:80 led_controller:latest

down:
	docker rm $$(docker stop $$(docker ps -a -q --filter ancestor=led_controller:latest --format="{{.ID}}"))

logs:
	docker logs -f led_controller

sh:
	docker exec -it led_controller /bin/bash
