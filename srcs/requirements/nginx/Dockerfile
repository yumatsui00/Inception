FROM debian:bullseye

RUN apt update -y && apt upgrade -y &&\
	apt install nginx -y &&\
	apt install curl -y &&\
	mkdir -p /etc/nginx/ssl &&\
	apt install openssl -y &&\
	openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt -keyout /etc/nginx/ssl/inception.key -subj "/C=JP/ST=Tokyo/L=Shinjuku/O=42Tokyo/OU=42Student/CN=yumatsui.42.fr/UID=yumatsui" &&\
	mkdir -p /var/run/nginx &&\
	cd /var/www/html

COPY	conf/nginx.conf /etc/nginx/nginx.conf



CMD ["nginx", "-g", "daemon off;"]

EXPOSE 443
