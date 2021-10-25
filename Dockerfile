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
	libipc-sharelite-perl \
	libdatetime-event-sunrise-perl \
	libdata-hexdump-perl \
	ffmpeg \
	imagemagick \
	tcpdump

USER root

RUN mkdir -p /led_controller/data
RUN mkdir -p /var/www/led_controller/images
RUN chown -R www-data:www-data /led_controller
RUN chown -R www-data:www-data /var/www/led_controller

RUN PERL_MM_USE_DEFAULT=1 cpan install Proc::Killall
RUN PERL_MM_USE_DEFAULT=1 cpan install IO::Async::Timer::Periodic

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
COPY ./artnet.conf /led_controller/

COPY ./LedController.pm /led_controller/
COPY ./LedController/Artnet.pm /led_controller/LedController/
COPY ./send_artnet_data.pl /led_controller/
COPY ./movie_to_artnet.pl /led_controller/
COPY ./led_control.pl /led_controller/
COPY ./sun_tracker.pl /led_controller/
COPY ./test.mov /led_controller/

COPY ./000-default.conf /etc/apache2/sites-available/
COPY ./startup.pl /etc/apache2/perl/
COPY ./index.epl /var/www/led_controller/
COPY ./upload.epl /var/www/led_controller/

CMD /docker-entrypoint.sh

