# Dockercompose.yml

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

serviceセクションにdocker compose で起動するサービスを一つずつ記入していく。その際に、imageやcontainerの名前、DockerFileの存在するパス、ポート、envファイル、volume,　networkなどを指定していく。


### volume

Docker Composeにおけるvolumesは、コンテナとホストマシン間のデータ共有を管理するために使用さ荒れる。これにより、通常コンテナが終了した際に消去されるデータをホストマシン上に保持し、再起動時にそのデータを使用することで、コンテナ上でデータを永続化することができる。ボリュームには三種類のボリュームが存在し、

- Named volumes

- Bind Mounts

- Anonymous Volume

の３つである。

### network

DockerCompoesのnetworkでは、復数のコンテナが相互に通信するための仮想ネットワークを定義する機能であり、これによりコンテナ同士が直接通信できるようになる。各コンテナは、ネットワークに接続すると独自のIPアドレスが割り当てられ、そのネットワーク内の他のコンテナと通信可能になる。
ネットワークにもいくつかの種類があり、主に以下のネットワークタイプが使用される。

- Bridge: デフォルトで作成されるネットワークで、同じブリッジネットワークに接続されたコンテナは互いに名前で通信できる。同じホスト上のコンテナ同士で、外部からのアクセスを制限しながら安全に通信可能。

- Host: コンテナがホストマシンのネットワークスタックを直接使用する。コンテナはホストのIPを共有し、コンテナ間でのIPアドレスを使用した通信が不要になる。コンテナがホストネットワークのパフォーマンスや設定をそのまま利用する必要がある際に使用するが、セキュリティの問題が発生する可能性がある。

- Overlay: 復数のDockerホストにまたがるネットワークを作成するためのネットワークタイプ。

- None: コンテナがネットワークに接続されない設定。