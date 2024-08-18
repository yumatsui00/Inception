# NGINX

NGINXはもともと高い同時接続能力を持つWebサーバーとして開発されたオープンソースのサービスである。
NGINXの設定に移る前に、キーワードの説明から始める。



### プロキシサーバー
クライアントとインターネット上の中間に位置する中継サーバー。クライアントからのリクエストを受け取り、それを目的のサーバーに転送した後に、サーバーから受け取った応答をクライアントに返す。
プロキシサーバーのいい点として

- 匿名性、セキュリティ　：クライアントのIPアドレスを隠し、別のIPアドレスを用いて外部のサーバーに接続する。
- キャッシュ機能　　　　：頻繁にアクセスするWebページのデータをプロキシサーバに保存することで、迅速なアクセスが可能になる。
- アクセス制限などの機能：特定のサイトなどへのアクセスを制限でき、学校や企業で有用

などがあげられる。また、フォワードプロキシ、リバースプロキシなどプロキシサーバーにも数種類存在する。

フォワードプロキシ：クライアント側に配置され、クライアントのリクエストをインターネット上の外部サーバーに転送する。通常は、特定の組織やグループ全体の人々のために設定される。
リバースプロキシ　：サーバー側に配置され、外部からのリクエストを受け取り、それを内部のバックエンドサーバーに転送する。ロードバランシングや、セキュリティ強化に繋がり、通常は特定の企業やサービスのために設定される。


### FastCGI
Webサーバーとアプリケーションサーバー（あたはスクリプト）感の通信を効率に行うためのプロトコルの一つで、PHP,Python,Perlといったスクリプト言語で書かれたプログラムとのやり取りで使用する。メリットとして

- 高パフォーマンス：従来のCGIと異なる方法で処理を行っており、動作が早い。
- 高スケーラビリティ：アプリケーションサーバーとWebサーバーを別々にスケーリング可能
- セキュリティ：Webサーバーとは別ユーザーとしてFastCGIプロセスが行われるため、Webサーバーの脆弱性がアプリケーションサーバーに影響を与えづらい
- 柔軟性：PHP,Pyton,Perlといった異なった言語のアプリケーションサーバーを同一のWebサーバーで動作可能

といった点があげられる。



## NGINX コンテナの設定

まず、NGINXコンテナで必要な設定を以下に示す
- TLSv1.2またはTLSv1.3のみをサポートするよう設定されたNGINXコンテナ
- ポート443のみがアクセスする唯一のエントリーポイント
- WordPressとはポート9000を通じて通信

### Dockerfile

RUNコマンドで必要なもの（nginx, openssl）をインストールすると同時に、秘密鍵を入れておくためのディレクトリを作成する。

```
RUN apt update -y && apt upgrade -y &&\
	apt install nginx -y &&\
	apt install curl -y &&\
	mkdir -p /etc/nginx/ssl &&\
	apt install openssl -y &&\
```

次に、秘密鍵をopensslコマンドを用いて取得する。（細かい説明略）

```
openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt -keyout /etc/nginx/ssl/inception.key -subj "/C=JP/ST=Tokyo/L=Shinjuku/O=42Tokyo/OU=42Student/CN=yumatsui.42.fr/UID=yumatsui" &&\
```

 後に説明する設定ファイルを、必要な場所にコピーし、CMDを実行。

 ```
 COPY	conf/nginx.conf /etc/nginx/nginx.conf

 CMD ["nginx", "-g", "daemon off;"]
```

以上のコマンドを入力することで、サーバーがフォアグラウンドで実行される。（Dockerコンテナは、フォアグラウンドでのプロセスが終了すると自動的に閉じてしまうため）


### 設定ファイル

NGINXの設定ファイルは、デフォルトではnginx.confという名前で、/usr/local/nginx/conf, /etc/nginx, /usr/local/etc/nginx　のうちのどこかに格納されている。
設定ファイルは、{}で囲まれたブロックのディレクティブと空白やセミコロンを用いたディレクティブによって記され、主に、eventsブロック、httpブロックの大きなブロックが２つ存在する。httpブロックの中にserverブロックが存在し、serverブロックの中にlocationブロックというものが存在する。

Webサーバーの主なタスクは、ファイルを提供することであり、クライアントからのリクエストによって、異なるローカルディレクトリから異なるファイルを提供できるように実装を行う。そのためには、locationブロックの編集が必要となる。httpブロックはサーバー名やポートのlisten番号によって復数のサーバーを含むことができるが、nginxがどのサーバーで処理を行うか判断しリクエストのヘッダーに指定されたURIをlocationブロック内のパラメータに対してテストしている。以下に設定ファイルの例を示す。

```
http {
	server{
		location / {
			root /data/www
		}
	}
}
```

このlocationブロックの/の部分は、ここで指定されたパスで始まるすべてのリクエストURIに対してこのlocationブロックが適用される、という意味である。"/"はすべてのURIに対してマッチするため、他のlocationブロックが存在して適用されない限り、この設定が適用される。リクエストがマッチしたら、URIにrootディレクティブで指定されたパス（今回は/data/www）が追加され、それがローカルファイルシステム状のリクエストされたファイルへのパスとなる。もし複数個の該当するlocationが存在した場合は、最も接頭辞の長いlocation が適用される。例えば、

```
http {
	server{
		location / {
			root /data/www
		}

		location /images/ {
			root /data
		}
	}
}
```

このような設定ファイルの時、http://localhost/images/example.png　というリクエストがクライアントから来た場合、nginxはローカルファイルで言う/data/images/example.pngを探して返す。
http://localhost/some/example.html　というリクエストには、/data/www/some/example.htmlファイルを探してくる。


次に、簡単なプロキシサーバーのセットアップについて

例１

```
server {
	listen 8080;
	root /data/upl;

	location / {
	}
}
```

 通常ポート80が空いているため、先程は指定しなかったが今回は8080に指定している。そして、すべてのリクエストはローカルディレクトリの/data/uplから探すことになる。
 例えば、https://localhost/some/example.txtはローカルディレクトリで言う、/data/upl/some/example.txtになる


 例２

 ```
 server {
	listen 5050;

	location / {
		proxy_pass http://localhost:8080;
	}

	location ~ \.(gif|jpg|png)$ {
		root /data/images;
	}
}
 ```

１つ目のlocationにマッチする場合、proxy_passで指定されたサーバーにリクエストが転送される。つまり、5050を介して来たリクエストがlocalhost:8080に転送され、返答をもらい、それを5050からクライアントに返す。
２つ目のlocationは正規表現 ~ を使用して、.gif, .jpg, .pngで終わるファイルを探している。今回の場合、以上の三種類のファイルをリクエストされた場合、ローカルディレクトリから探し、それ以外を転送している


例３
```
servet {
	location = /exact-match {
		#完全一致、優先度１
	}
	location ^~ /images/ {
		#正規表現より優先される、優先度２
	}
	location ~ \.(gif|jpg|png)$ {
		#正規表現、優先度３
	}
	location / {
		#通常表現、優先度４
		#その中でもprefixの長いものが優先される
	}
}
```

これは、locationの記法と優先度を示した。


例４

```
server {
	location / {
		fastcgi_pass	localfast:9000;
		fastcgi_param	SCRIPT_FILENAME $document_root$fastcgi_script_name;
		fastcgi_param	QUERY_STRING　$query_string;
	}

	location ~ \.(gif|jpg|png)$ {
        root /data/images;
    }
}
```

これはFastCGIのプロキシのセットアップであり、fastcgi_passのパスを介してリクエストを転送し、同時にfastcgi_paramで指定されたスクリプトのパスとクエリ文字列をFastCGIプロセスに渡す。
paramがない場合は、環境変数設定に基づいてリクエストを送信する。



NGINXの仕組みとして、マスタープロセスとワーカープロセスが存在し、マスタープロセスはせて血ファイルの読み込み、評価とワーカープロセスの維持を、ワーカープロセスはリクエストの処理を主に担当している。設定ファイルをせってすることで、ワーカープロセスの数なども設定できる。



### その他、メモ
index
クライアントがディレクトリにアクセスしたときに優先的に表示するファイルを指定できる


Nginxの主要な設定ファイルとディレクトリ
メイン設定ファイル　/etc/nginx/nginx.conf
全体の基本的な設定や、他の設定ファイルを読み込むためのinclude ディレクティブが含まれている

仮想ホストの設定ファイル　/etc/nginx/site-available
defaultはその中でも、デフォルトの設定ファイル

仮想ホスト設定ファイルへのシンボリックリンク　/etc/nginx/sites-enabled
シンボリックリンクはポインタ型のファイルのイメージ。ここに記述されたファイルだけが有効になる

追加の設定ファイル /etc/nginx/conf.d
特定のモジュールの追加の構成要素(SSLやロギング設定)をここに保存するのが一般的で、nginx.confでこのファイルを読み込むように指定するのが一般的




URIについて
scheme://authority/path?query#fragment

ex
https://chatgpt.com/c/asfasdf

scheme: リソースへのアクセス方法
authority: リソースが存在するサーバーを示す。通常はドメイン名（またはIP）と、必要に応じてポート番号が含まれる　ex)127.0.0.1:8080
path: path
