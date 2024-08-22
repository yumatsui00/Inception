#!/bin/bash

service mariadb start
sleep 5

mysql -uroot -p"$MYSQL_PASSWORD" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}'; FLUSH PRIVILEGES;"

# mariadb -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\`;"

# mariadb -e "CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"

# mariadb -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"


mysql -uroot -p"$MYSQL_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\`;"
mysql -uroot -p"$MYSQL_PASSWORD" -e "CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -uroot -p"$MYSQL_PASSWORD" -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -uroot -p"$MYSQL_PASSWORD" -e "FLUSH PRIVILEGES;"

mariadb -e "FLUSH PRIVILEGES;"

mysqladmin -u root -p$MYSQL_ROOT_PASSWORD shutdown

mysqld_safe --port=3306 --bind-address=0.0.0.0 --datadir='/var/lib/mysql'