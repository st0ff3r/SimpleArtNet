all: build up

build:
	docker build -t led_controller:latest .

up:
	docker run -dit led_controller:latest

down:
	docker rm $$(docker stop $$(docker ps -a -q --filter ancestor=led_controller:latest --format="{{.ID}}"))
