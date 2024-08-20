FROM	debian:bullseye

RUN apt update -y && apt upgrade -y &&\
	apt-get	install mariadb-server -y

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY ./tools/mdb-conf.sh /mdb-conf.sh

RUN chmod +x /mdb-conf.sh

ENTRYPOINT ["/mdb-conf.sh"]