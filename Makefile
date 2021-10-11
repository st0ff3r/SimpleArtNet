all: build up

build:
	docker build -t led:latest .

up:
	docker run -dit led:latest
