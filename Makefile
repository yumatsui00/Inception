WP_PATH = /home/yumatsui/html
MariaDB_PATH = /home/yumatsui/mariadb

all: up

up: inception
	@mkdir -p $(WP_PATH)
	@mkdir -p $(MariaDB_PATH)
	@sudo chmod -R 755 $(WP_PATH)
	@sudo chmod -R 755 $(MariaDB_PATH)
	docker-compose -f srcs/docker-compose.yml up -d

build:
	docker-compose -f srcs/docker-compose.yml build

down:
	docker-compose -f srcs/docker-compose.yml down

stop:
	docker-compose -f srcs/docker-compose.yml stop

volumerm:
	@rm -rf $(WP_PATH)
	@rm -rf $(MariaDB_PATH)
	docker volume rm wordpress
	docker volume rm mariadb

clean:
	docker rmi wordpress mariadb nginx

inception:

	@ echo "\033[93m██████████████████████████████████████████████████████"
	@ echo "█▄─▄█▄─▀█▄─▄█─▄▄▄─█▄─▄▄─█▄─▄▄─█─▄─▄─█▄─▄█─▄▄─█▄─▀█▄─▄█"
	@ echo "██─███─█▄▀─██─███▀██─▄█▀██─▄▄▄███─████─██─██─██─█▄▀─██"
	@ echo "▀▄▄▄▀▄▄▄▀▀▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▄▄▄▀▀▀▀▄▄▄▀▀▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀"