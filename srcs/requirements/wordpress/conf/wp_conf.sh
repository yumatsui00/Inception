#!/bin/bash

mkdir /var/www

mkdir /var/www/html

cd /var/www/html

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

chmod +x wp-cli.phar

mv wp-cli.phar /usr/local/bin/wp

wp core download --allow-root


ping_mariadb_container() {
    nc -zv mariadb 3306 > /dev/null
    return $?
}

start_time=$(date +%s)
end_time=$((start_time + 15))
while [ $(date +%s) -lt $end_time ]; do
    ping_mariadb_container
    if [ $? -eq 0 ]; then
        echo "[========MARIADB IS UP AND RUNNING========]📈"
        break
    else
        echo "[========WAITING FOR MARIADB TO START...========]🤔"
        sleep 1
    fi
done

if [ $(date +%s) -ge $end_time ]; then #-ge : greater than or equal to ~
    echo "[========MARIADB IS NOT RESPONDING========]🏳"
fi

wp config create --dbhost=mariadb:3306 --dbname="$MYSQL_DB" --dbuser="$MYSQL_USER" --dbpass="$MYSQL_PASSWORD" --allow-root

wp core install --url="$DOMAIN_NAME" --title="$WP_TITLE" --admin_user="$WP_ADMIN_N" --admin_password="$WP_ADMIN_P" --admin_email="$WP_ADMIN_E" --allow-root

wp user create "$WP_U_NAME" "$WP_U_EMAIL" --user_pass="$WP_U_PASS" --role="$WP_U_ROLE" --allow-root

# いる？
# wp search-replace 'http://localhost' "http://$DOMAIN_NAME"

sed -i '36 s@/run/php/php7.4-fpm.sock@9000@' /etc/php/7.4/fpm/pool.d/www.conf

mkdir -p /run/php

/usr/sbin/php-fpm7.4 -F
