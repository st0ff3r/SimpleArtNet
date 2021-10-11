all: build up

build:
	docker build -t led:latest .

up:
	docker run -dit led:latest

down:
	docker rm $$(docker stop $$(docker ps -a -q --filter ancestor=led:latest --format="{{.ID}}"))
