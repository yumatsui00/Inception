WP_PATH = /home/data/html
MariaDB_PATH = /home/data/mariadb

all: up

up:
	@mkdir -p $(WP_PATH)
	@mkdir -p $(MariaDB_PATH)
	docker-compose -f srcs/docker-compose.yml up -d

build:
	docker-compose -f srcs/docker-compose.yml build

down:
	docker-compose -f srcs/docker-compose.yml down

stop:
	docker-compose -f srcs/docker-compose.yml stop