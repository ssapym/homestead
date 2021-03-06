#!/usr/bin/env bash

mkdir /etc/nginx/ssl 2>/dev/null
openssl genrsa -out "/etc/nginx/ssl/$1.key" 1024 2>/dev/null
openssl req -new -key /etc/nginx/ssl/$1.key -out /etc/nginx/ssl/$1.csr -subj "/CN=$1/O=Vagrant/C=UK" 2>/dev/null
openssl x509 -req -days 365 -in /etc/nginx/ssl/$1.csr -signkey /etc/nginx/ssl/$1.key -out /etc/nginx/ssl/$1.crt 2>/dev/null

block="server {
    listen ${3:-80};
    server_name $1;
    root \"$2\";

    index index.html index.htm;

    charset utf-8;

    location / {
        root \"$2/templates\";
        try_files \$uri \$uri/ /index.html /index.htm;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/$1-error.log error;

    sendfile off;

    client_max_body_size 100m;

    location /api {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:8000;
    }

    location /static {
        alias \"$2/static\"; # your Django project's static files - amend as required
    }

    location /media  {
        alias \"$2/media\";  # your Django project's media files - amend as required
    }

    location ~ /\.ht {
        deny all;
    }
}
server {
    listen ${4:-443};
    server_name $1;
    root \"$2\";

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        root \"$2/templates\";
        try_files \$uri \$uri/ /index.html /index.htm;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/$1-ssl-error.log error;

    sendfile off;

    client_max_body_size 100m;

    location /api {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:8000;
    }

    location /static {
        alias \"$2/static\"; # your Django project's static files - amend as required
    }

    location /media  {
        alias \"$2/media\";  # your Django project's media files - amend as required
    }

    location ~ /\.ht {
        deny all;
    }

    ssl on;
    ssl_certificate     /etc/nginx/ssl/$1.crt;
    ssl_certificate_key /etc/nginx/ssl/$1.key;
}
"

echo "$block" > "/etc/nginx/sites-available/$1"
ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"
service nginx restart
