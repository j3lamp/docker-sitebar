# SiteBar docker image

Easy usable docker image for [SiteBar](http://sitebar.org), the online bookmark manager.

## Features

* Uses latest stable version of **Alpine Linux**, bundled with **PHP 7** and **NGinx**.
* APCu already configured.
* Persistence for configuration.
* Works with MySQL/MariaDB and PostgreSQL (server not included).

## Container environment

### Included software

* Alpine Linux
* **PHP 7**
* APCu
* NGinx
* SupervisorD

Everything is bundled in the newest stable version.

### Tags

* **latest**: latest stable SiteBar version (PHP 7)
* **X.X.X**: stable version tags of SiteBar (e.g. v3.6) (Version >= 12.0.0 use PHP 7)
* **develop**: latest development branch (may unstable)

### Build-time arguments
* **UID**: User ID of the sitebar user (default 1502)
* **GID**: Group ID of the sitebar user (default 1502)

### Exposed ports
- **80**: NGinx webserver running SiteBar.

### Volumes
- **/config** : The configuration directory.

## Usage

### With a database container

```
# docker pull j3lamp/sitebar && docker pull mariadb:10
# docker run -d --name sitebar_db -v my_db_persistence_folder:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=supersecretpassword -e MYSQL_DATABASE=sitebar -e MYSQL_USER=sitebar -e MYSQL_PASSWORD=supersecretpassword mariadb:10
# docker run -d --name sitebar --link sitebar_db:sitebar_db -p 80:80 -v my_local_config_folder:/config j3lamp/sitebar
```

*The auto-connection of the database to SiteBar is not implemented yet. This is why you need to do that manually.*

### Run container with systemd

I usually run my containers on behalf of systemd, with the following config:

```
[Unit]
Description=Docker - SiteBar container
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run -p 127.0.0.1:8000:80 -v /data/sitebar:/config --name sitebar j3lamp/sitebar
ExecStop=/usr/bin/docker stop -t 2 sitebar ; /usr/bin/docker rm -f sitebar

[Install]
WantedBy=default.target
```

### NGinx frontend proxy

This container does not support SSL or similar and is therefore not made for running directly in the world wide web. You better use a frontend proxy like another NGinx.

Here are some sample configs (The config need to be adapted):

```
server {
  listen 80;
  server_name cloud.example.net;

  # ACME handling for Letsencrypt
  location /.well-known/acme-challenge {
    alias /var/www/letsencrypt/;
    default_type "text/plain";
    try_files $uri =404;
  }

  location / {
    return 301 https://$host$request_uri;
  }
}

server {
  listen 443 ssl spdy;
  server_name cloud.example.net;

  ssl_certificate /etc/letsencrypt.sh/certs/cloud.example.net/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt.sh/certs/cloud.example.net/privkey.pem;
  ssl_trusted_certificate /etc/letsencrypt.sh/certs/cloud.example.net/chain.pem;
  ssl_dhparam /etc/nginx/dhparam.pem;
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

  ssl_session_cache shared:SSL:10m;
  ssl_session_timeout 30m;

  ssl_prefer_server_ciphers on;
  ssl_ciphers "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";

  ssl_stapling on;
  ssl_stapling_verify on;

  add_header Strict-Transport-Security "max-age=31536000";

  access_log  /var/log/nginx/docker-sitebar_access.log;
  error_log   /var/log/nginx/docker-sitebar_error.log;

  location / {
    proxy_buffers 16 4k;
    proxy_buffer_size 2k;

    proxy_read_timeout 300;
    proxy_connect_timeout 300;
    proxy_redirect     off;

    proxy_set_header   Host              $http_host;
    proxy_set_header   X-Real-IP         $remote_addr;
    proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header   X-Frame-Options   SAMEORIGIN;

    client_max_body_size 10G;

    proxy_pass http://127.0.0.1:8000;
  }
}
```

## Group/User ID

You can change the numerical user id and group id via build arguments.

```
$ git clone https://github.com/j3lamp/docker-sitebar.git && cd docker-sitebar
$ docker build -t j3lamp/sitebar --build-arg UID=1000 --build-arg GID=1000 .
$ docker run -p 80:80 j3lamp/sitebar
```

## References

This is based heavily on [https://github.com/chrootLogin/docker-nextcloud](https://github.com/chrootLogin/docker-nextcloud).
