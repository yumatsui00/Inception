FROM debian:bullseye

RUN apt-get update && apt-get upgrade -y &&\
	apt-get install -y curl php php7.4-fpm php-mysql mariadb-client iputils-ping wget vim zsh git netcat mycli

COPY /conf/wp_conf.sh /

RUN  chmod +x wp_conf.sh

ENTRYPOINT ["/wp_conf.sh"]
