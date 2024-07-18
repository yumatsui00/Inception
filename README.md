# Inception

## Docker について
### Docker のメリット
Docker とは、簡単に言うと、アプリケーションと、その依存関係を分離されたコンテナにパッケージすることができるツールです。
- 家で作ったプログラムが、学校のPCでは実行できなかった、、、
- githubからとってきた誰かのプログラムを実行しようとしたら、不足している依存関係があった、、、
- ファイルのバージョンが、自分のOSと互換性がなかった、、、

といった問題を解決できる。仮想環境で解決できる問題ではあるが、Dockerを使うことで
1. 各コンテナを、保存できるイメージ形式でモデル化できる
2. コンテナイメージにより、開発環境と本番環境の一貫性を保てる
3. OSのカーネル共有をするため、仮想マシンに比べ軽量で、起動時間も短い
4. (DockerHub)[https://hub.docker.com/] から、いろいろなコンテナイメージを共有できる

といった利点がある。例えば、Webサイトを運営するときに、(NGINX（Webサーバーソフトの１つ）)[https://nginx.org/en/]をインストールする必要があるとします。通常通りにインストールするには、適切なOSや依存関係が必要となる。
しかし、NGINXのドッカーイメージはNGINXによってDockerHub)[https://hub.docker.com/]に公開されており、Dockerコンテナを用いてこれをインストールすればそれらの問題を解決できる。
NGINXイメージ例
```
						FROM		alpine:3.12

						RUN			apk update && apk upgrade && apk add	\
													openssl			\
													nginx			\
													curl			\
													vim				\
													sudo

						RUN			rm -f /etc/nginx/nginx.conf

						COPY		./config/nginx.conf /etc/nginx/nginx.conf
						COPY		scripts/setup_nginx.sh /setup_nginx.sh

						RUN			chmod -R +x /setup_nginx.sh

						EXPOSE		443

						ENTRYPOINT	["sh", "setup_nginx.sh"]
```

このファイルをDockerfileとよび、ドッカーイメージのメインファイルです。

## Dockerfileのキーワード
### FROM
基本構文
```
FROM <イメージ名>[:<タグ>]
```
- イメージ名：どのOSやベースイメージに基づいて、Dockerイメージが構築されているかを示す。
- タグ：イメージ名のバージョンやバリエーションを示す

例
```
Debian
FROM debian:buster
Linux
FROM alpine:x:xx
Ubunts
FROM ubuntu:20.04
```


### RUN
基本構文
```
RUN <コマンド>
```
RUN命令は、新しいレイヤーを作成し、指定されたコマンドを実行するために使用される。コマンド実行により、
- 必要なソフトウェアや依存関係のインストール
- システムのセットアップ
- 環境設定
- 不要なファイルの消去やキャッシュの削除
といった、ドッカーイメージ構築に必要なすべての準備を行う。また、RUN命令にはシェル形式とExec形式の２種類が存在し、
```
シェル形式
RUN apt-get update && apt-get install -y curl
Exec形式
RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "curl"]
```
以上のような違いがある。


### COPY
基本構文
```
COPY <ソース> <コピー先>
```
Dockerfile内で、ホストマシンからコンテナイメージ内にファイルやディレクトリをコピーするために使用される。
RUNコマンド内でコピーを行うことも可能だが、COPY命令を行うことで、可読性の向上、キャッシュの適切な利用によるビルド時間の短縮、無駄なレイヤーを作成しない効率的なイメージの作成といった観点から、COPY命令の使用が推奨される。


### EXPOSE
基本構文
```
EXPOSE　<ポート番号>　[<ポート番号２>...]
```
EXPOSE命令は、命令と名付けられて入るものの、ドキュメントとしての役割が強い。コンテナがどのポートでリスんしているかを明示しており、他の開発者がコンテナのネットワーク設定を理解しやすくするために存在している。
そのため、EXPOSE命令自体はポートを公開するのではなく実際に公開するには、.ymlファイルで追加の設定が必要となる。


### ENTRYPOINT
基本構文
```
シェル形式
ENTRYPOINT <command>
```
Dockerfile内でコンテナが起動された際に、最初に自動的に実行されるメインプロセスを指定するために使用される。EXEC形式も可。例として、
```
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```
のように設定しておくと、コンテナの起動と同時に、entrypoint.shというスクリプトを実行することができる。



## Docker Compose

docker compose は復数のコンテナを定義、管理するためのツールで、サービスを定義するyamlファイルを作成し、単一のコマンドですべてのサービスの起動、停止や、コンテナ間での通信が可能となる。
例えば、42学生の使用するintraを構築するにはNGINXを使ったウェブサイト、intraポータルサイトのサービス、出退勤を記録するデータベース、が必要となる。これらをDocker Composeを用いて管理するために、以下のようなdocker-compose.ymlを作成する。

```
version: "3"

services:
  website:
    build: requirements/website/
    env_file: .env
    container_name: website
    ports:
      - "80:80"
    restart: always

  intra:
    build: requirements/intra/
    env_file: .env
    container_name: intra
    ports:
      - "80:80"
    restart: always

  badgeuse:
    container_name: badgeuse
    build: mariadb
    env_file: .env
    restart: always
```

このDockercomposeと同一ディレクトリ上で、docker-compose build や、　docker-compose up -d, docker-compose down といったコマンドを入力するだけで、サービスの起動、停止を簡単に行える。


## プロジェクトの概要
このプロジェクトは、Dockerを使用して複数のサービスを仮想化し、小規模なインフラを設定するもであり、以下の要件に従い仮想マシン内で実行する。

### サービスの設定
- 各Dockerイメージは対応するサービスと同じ名前を持つ
- 各サービスは専用コンテナで実行される
- コンテナは最新安定版の一つ前のバージョンのAlpineまたはDebianからBuildされる
- 各サービスごとにDockerfileを作成し、Makefileを用いてdocker-compose.ymlで呼び出す
- Alpine, Debianを除き、DockerHubなどの既製のドッカーイメージの使用は禁止

### コンテナの設定
- NGINX TLSv1.2またはTLSv1.3のみをサポートするよう設定されたNGINXコンテナ
- WordPress NGINXを含まず、WordPressとphp-fpmをインストールして設定するコンテナ
- MaruaDB　NGINXを含まずにMairaDBをインストールしたコンテナ
- ボリューム
  - WordPressデータ用のボリューム
  - WordPressサイトファイル用のボリューム
- ネットワーク　コンテナ間通信を確立するためのdocker-network  

### その他の要件
- コンテナはクラッシュ時に再起動する必要がある
- 無限ループやtail -lといったコマンドは使用禁止
- WordPressデータベースには２人のユーザーが必要。一人は管理者。
- 管理者のユーザー名に、"admin"や"administrator"を含めてはいけない
- ホストマシンの/home/login/dataフォルダにボリュームを配置する
- ローカルIPアドレスにドメイン名を設定する。ドメイン名はlogin.42.fr（自分のログイン名）
- .envファイルを使用して環境変数を管理し、パスワードはDockerfile煮含めない
- NGINXコンテナはポート443のみを通じてインフラストラクチャにアクセスする唯一のエントリーポイントである

### Bonus
- WordPressサイトのキャッシュを適切に管理するためのRedisキャッシュ
- WordPressサイトのファイルのボリュームに接続するFTPサーバーのコンテナの設定
- PHP以外の言語で作成されたシンプルな静的サイトの作成（例：ポートフォリオ）
- Adminerの設定
- その他、有用であると考える任意のサービスを設定

```
project-root/
├── Makefile
├── srcs/
│   ├── docker-compose.yml
│   ├── .env
│   └── requirements/
│       ├── mariadb/
│       │   ├── Dockerfile
│       │   └── ...
│       ├── nginx/
│       │   ├── Dockerfile
│       │   └── ...
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   └── ...
│       └── bonus/
│           └── ...
```
![Screenshot from 2024-07-19 04-41-04](https://github.com/user-attachments/assets/a4240699-400d-40fd-a434-3c8ab402377a)






