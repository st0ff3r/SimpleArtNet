#
# uIota Dockerfile
#
# The resulting image will contain everything needed to build uIota FW.
#
# Setup: (only needed once per Dockerfile change)
# 1. install docker, add yourself to docker group, enable docker, relogin
# 2. # docker build -t uiota-build .
#
# Usage:
# 3. cd to MeterLoggerWeb root
# 4. # docker run -t -i -p 8080:80 meterloggerweb:latest


FROM debian:buster

MAINTAINER Kristoffer Ek <stoffer@skulp.net>

RUN "echo" "deb http://http.us.debian.org/debian buster non-free" >> /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
	aptitude \
	autoconf \
	automake \
	aptitude \
	bash \
	bison \
	cpanplus \
	flex \
	g++ \
	gawk \
	gcc \
	git \
	inetutils-telnet \
	joe \
	make \
	sed \
	sudo \
	screen \
	rsync \
	apache2 \
	apache2-bin \
	apache2-doc \
	apache2-utils \
	libapache2-mod-perl2 \
	libapache2-mod-perl2-dev \
	libapache2-mod-perl2-doc \
	libembperl-perl \
	libconfig-simple-perl \
	software-properties-common \
	libimage-magick-perl \
	libimage-size-perl \
	ffmpeg \
	imagemagick

USER root

RUN mkdir -p /led

#RUN PERL_MM_USE_DEFAULT=1 cpan install Net::MQTT::Simple

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
COPY ./artnet.conf /led/

COPY ./Artnet.pm /led/
COPY ./send_artnet_data.pl /led/
COPY ./movie_to_artnet.pl /led/
COPY ./test.mov /led/
COPY ./artnet.data /led/

CMD /docker-entrypoint.sh

