# Wordopress

オープンソースのコンテンツ管理システムCMS.Webサイトの作成、管理をするためのプラットフォーム


## WordPressを用いたWebサイト作成の手順

WordPressを用いたWebサイト作成の手順
１，ドメインの取得
２，Webホスティングサービスの利用
３，サーバーの設定
４，WordPressをサーバーにインストールし、テーマやプラグインを設定してサイトを構築する

ここで、今回はlocalhostで個人としてのサーバーを構築するだけなので、１，２はする必要がない。
１はドメイン名に当たる部分がlocalhostになっているから。
2は、サーバーを設置するためのパブリックな場所を提供するサービスのことであり、公開する必要のない今回は関係がない。


今回ではwordpressは自身のコンテナにダウンロードし、fastcgiを介してnginxと通信試合、サイトを構築する。nginxの役割はそのルーティングを行うこと


## Dockerfileと、実行ファイルの作成

ドッカーファイルでは必要なものをダウンロードして、実行ファイルを起動するのみ。
実行ファイルでは、まずvolumeがマウントされる場所を作成し、移動する。（volumeについてはドッカーファイル）


そして、wp-cli.pharをダウンロードし、実行権限を与える。

```
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

chmod +x wp-cli.phar
```

wp-phar は　WordPress-Command Line Interface php archiveのことで、これをダウンロードすると、wordpressをコマンドライン上で操作することができるようになる。また、mvコマンドでbinに移すときに、名前をwpに変えることで、　wpというコマンドとして以降使用可能にしている。

そして、wordpressをダウンロードする。

```
wp core download --allow-root
```

wordpressはルートユーザーでの実行時にセキュリティの都合上警告を出すが、--allow-rootのオプションをつけることで警告を無視している。


次に、mariadbの部分であるが、これはmaraidbとの接続が成功しているかを確認しているだけなので省略。


### 設定ファイル

wordpressの設定ファイルであるwp-config.phpはwordpressインストールを行う上で最も重要なファイルの一つで、ファイルディレクトリのルート直下に置かれ、データベースの接続情報などが含まれている。ダウンロード直後のWordpressにはこのファイルが含まれていないのだが、Wordpressをセットアップする過程で入力された情報をもとに、wp-conf.phpが自動的に生成される。また、インストール直下にあるwp-config-sample.phpを必要に応じて編集し、その名前をwp-config.phpにすることで、手動作成も可能となる。

インストール作業時にwp-conf.phpを編集するには以下の情報が必要となる。
１．データベース名
２，データベースユーザー名
３，データベースパスワード
４，データベースホスト

```
wp config create --dbhost=mariadb:3306 --dbname="$MYSQL_DB" --dbuser="$MYSQL_USER" --dbpass="$MYSQL_PASSWORD" --allow-root
```

今回はwp core configコマンドを用いることで、コマンドライン上でconfigファイルの基本設定をしており、.envファイルで設定した情報をもとに、接続するポート番号から、データベース名などの初期設定を行っている


```
wp core install --url="$DOMAIN_NAME" --title="$WP_TITLE" --admin_user="$WP_ADMIN_N" --admin_password="$WP_ADMIN_P" --admin_email="$WP_ADMIN_E" --allow-root
```

次に、　wordpressのタイトルや、管理者名、パスワードなどを設定している。core downloadはコアファイルを公式リポジトリからダウンロードするためのコマンドで、必要なファイル一式をダウンロードし、wordpressインストールの準備をするのに対し、core install は初期インストールとサイトの基本設定を行うためのコマンドで、これによりデータベースに必要なテーブルが作成され、サイトを初期設定を行えるようにしている。


```
wp user create "$WP_U_NAME" "$WP_U_EMAIL" --user_pass="$WP_U_PASS" --role="$WP_U_ROLE" --allow-root
```

このコマンドでは、管理者ではないユーザーを作成している。roleという項目でユーザーの役割を設定できる。


```
sed -i '36 s@/run/php/php7.4-fpm.sock@9000@' /etc/php/7.4/fpm/pool.d/www.conf
```

このコマンドでは、php-fpmがfastCGIのリクエストを受け付けるための方法をデフォルトのUNIXソケットからTCPポート9000に変更している。　
UNIXソケット：同一システムナインのプロセス間通信を行うためのインターフェースで、同一コンテナ内での使用が有効。



```
/run/php
```

これは、php-fpmのソケットディレクトリを作成している。php-fpmはリクエストを処理するためにソケットファイルを使用し、デフォルトではこのソケットファイルが/run/php内に作成される。このディレクトリはシステムが起動するたびに再作成される一時的なディレクトリで、システム再起動後に消えることがあり、それによるエラーの発生を防いでいる。このファイルがないとプロセス間通信ができなくなってしまう。


```
/usr/sbin/php-fpm7.4 -F
```

最後に、以上のコマンドを使用することで、php-fpm7.4をフォアグラウンドで実行し、コンテナの終了を防いでいる