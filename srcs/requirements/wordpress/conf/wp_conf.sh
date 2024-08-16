#!/bin/bash

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

chmod +x wp-cli.phar

mv wp-cli.phar /usr/local/bin/wp

cd /var/www/wordpress

chmod -R 755 /var/www/wordpress/

chown -R www-data:www-data /var/www/wordpress

#---------------------------------------------------ping mariadb---------------------------------------------------#
# check if mariadb container is up and running
ping_mariadb_container() {
    nc -zv mariadb 3306 > /dev/null # ping the mariadb container
    return $?
}

start_time=$(date +%s)
end_time=$((start_time + 5))
while [ $(date +%s) -lt $end_time ]; do
    ping_mariadb_container
    if [ $? -eq 0 ]; then
        echo "[========MARIADB IS UP AND RUNNING========]📈"
        break # Exit the loop if MariaDB is up
    else
        echo "[========WAITING FOR MARIADB TO START...========]🤔"
        sleep 1d
    fi
done

if [ $(date +%s) -ge $end_time ]; then #-ge : greater than or equal to ~
    echo "[========MARIADB IS NOT RESPONDING========]🏳"
fi

# download wordpress core files
#wp core download: WP-CLIのcoreコマンドの一部で、WordPressのコアファイルをダウンロードするために使用します。これは、WordPressを新規にインストールする際の最初のステップとして使用されます。
#--allow-root: このオプションは、rootユーザーでコマンドを実行する際に必要です。通常、セキュリティの理由から、rootユーザーでの操作は推奨されませんが、Dockerコンテナや特定のサーバー設定では必要となる場合があります。
wp core download --allow-root
# create wp-config.php file with database details
#wp core config: WP-CLIのcoreコマンドの一部で、WordPressの設定ファイル（wp-config.php）を生成するために使用します。このファイルには、WordPressがデータベースと通信するための設定が含まれます。
#--dbhost=mariadb:3306: データベースサーバーのホスト名とポート番号を指定します。ここでは、データベースがmariadbというホスト名で、ポート3306（MariaDBやMySQLのデフォルトポート）で動作していると仮定しています。
#--dbname="$MYSQL_DB": データベースの名前を指定します。この変数$MYSQL_DBには、使用するデータベース名が事前に設定されている必要があります。たとえば、wordpress_dbのようなデータベース名がここに入ります。
#--dbuser="$MYSQL_USER": データベースにアクセスするためのユーザー名を指定します。$MYSQL_USER変数には、データベースユーザー名が設定されている必要があります。例えば、rootやwordpress_userなどです。
#--dbpass="$MYSQL_PASSWORD": データベースユーザーのパスワードを指定します。$MYSQL_PASSWORD変数には、このユーザーのパスワードが設定されている必要があります。
#--allow-root: このオプションは、rootユーザーでコマンドを実行する際に使用します。通常、セキュリティ上の理由から、rootユーザーでの操作は避けるべきですが、特定のサーバー環境では必要となる場合があります。
wp core config --dbhost=mariadb:3306 --dbname="$MYSQL_DB" --dbuser="$MYSQL_USER" --dbpass="$MYSQL_PASSWORD" --allow-root
# install wordpress with the given title, admin username, password and email
#wp core install: WP-CLIのcoreコマンドの一部で、WordPressのインストールを行います。
#--url="$DOMAIN_NAME": WordPressサイトのURLを指定します。例えば、https://example.comなどのドメイン名がここに入ります。
#--title="$WP_TITLE": サイトのタイトルを指定します。このタイトルは、サイトのフロントエンドや管理画面で表示されるものです。
#--admin_user="$WP_ADMIN_N": WordPressの管理者ユーザー名を指定します。このユーザーは、WordPressサイトの全ての管理権限を持つアカウントとなります。
#--admin_password="$WP_ADMIN_P": 管理者ユーザーのパスワードを指定します。セキュリティのために強力なパスワードを設定することが推奨されます。
#--admin_email="$WP_ADMIN_E": 管理者ユーザーのメールアドレスを指定します。このメールアドレスは、サイトの重要な通知やパスワードリセットのために使用されます。
#--allow-root: このオプションは、rootユーザーでコマンドを実行する場合に必要です。通常、セキュリティの観点から、rootユーザーでの操作は避けるべきですが、コンテナ環境や特定のサーバー構成では必要となる場合があります。
wp core install --url="$DOMAIN_NAME" --title="$WP_TITLE" --admin_user="$WP_ADMIN_N" --admin_password="$WP_ADMIN_P" --admin_email="$WP_ADMIN_E" --allow-root
#create a new user with the given username, email, password and role
# wp user create <username> <email> --role=<role> --user_pass=<password>
#<username>: 作成するユーザーのユーザー名を指定します。
#<email>: ユーザーのメールアドレスを指定します。
#--role=<role>: ユーザーの役割を指定します（例: subscriber, contributor, author, editor, administrator）。
#--user_pass=<password>: ユーザーのパスワードを指定します。
wp user create "$WP_U_NAME" "$WP_U_EMAIL" --user_pass="$WP_U_PASS" --role="$WP_U_ROLE" --allow-root

# change listen port from unix socket to 9000
# 　php_hpmがfastCGIのリクエストを受け付けるための方法をUNIXソケットからTCPポート9000に変更している。
# これは、あくまでphp-hpmの内部設置絵の一部であり、ネットワーク構成を変えるものではない
# UNIXソケットについて　同一システム内のプロセス間通信を行うためのインターフェース。同一コンテナ内での使用が有効。異なるコンテナ感で間ではTCP
sed -i '36 s@/run/php/php7.4-fpm.sock@9000@' /etc/php/7.4/fpm/pool.d/www.conf
# create a directory for php-fpm
mkdir -p /run/php
# start php-fpm service in the foreground to keep the container running
#フォアグラウンドで実行。バックグラウンドで実行しようとして、フォアグラウンドに実行するコマンドがないとセル自体が終了し、シェルが終了すると、コンテナのメインプロセスが終了したとみなされコンテナ自体が修了する。しかし、フォアグラウンドで実行されている場合は維持可能
/usr/sbin/php-fpm7.4 -F