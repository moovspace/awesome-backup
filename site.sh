#!/bin/bash
# Debian 10, nginx, php 7.3, php7.3-fpm
# Create site and ssl for virtualhosts
# Create DNS A or CNAME records for vhosts:  
# Sites: example.com and www.example.com

# variables
PHP_FPM="7.3"
MAX_UPLOAD=100
CHOWN_USER="debian"

if [ $(id -u) -ne 0 ];then
    echo "Please run as root with sudo:"
    echo "sudo bash site.sh example.com /var/www/html certbot_alert@example.com"
    exit
fi

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
    echo "Wrong script arguments try with root user and sudo:"
    echo "sudo bash site.sh example.com /var/www/html alert@example.com"
    exit
fi

# tests
if [ ! -z $1 ]; then
    DOMAIN="$1"
fi

if [ ! -z $2 ]; then
    HTML_DIR="$2"
fi

if [ ! -z $3 ]; then
    EMAIL="$3"
fi

if [ ! -z $4 ]; then
    MAX_UPLOAD="$4"
fi

# validate email address
regex="^(([-a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~-]|(\\\\[\\ \"]))+\"))\.)*([-a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~-]|(\\\\[\\ \"]))+\"))@\w((-|\w)*\w)*\.(\w((-|\w)*\w)*\.)*\w{2,4}$"
if [[ ${EMAIL} =~ $regex ]] ; then
    echo "Valid email addres"
else
    echo ""
    echo "Invalid email address !!!"
    echo ""
    exit 1
fi

echo "Installing ---> packages"
# install
apt install nginx php php-fpm certbot

echo "Creating ---> document root directory"
# create dir
if [ ! -d ${HTML_DIR}/${DOMAIN} ];then
    mkdir -p ${HTML_DIR}/${DOMAIN}
fi

echo "Creating ---> website index.php"
# index php hml
echo "Works..." > ${HTML_DIR}/${DOMAIN}/index.php
echo "Works..." > ${HTML_DIR}/${DOMAIN}/index.html

echo "Creating ---> virtual hosts"
# add http host
echo -e "
server {
    gzip on;
    gzip_static on;
    gunzip on;

    charset utf-8;
    client_max_body_size ${MAX_UPLOAD}M;
    disable_symlinks off;
    keepalive_timeout 60;

    listen 80;
    listen [::]:80;

    root ${HTML_DIR}/${DOMAIN};
    server_name ${DOMAIN} www.${DOMAIN};
    index index.php index.html;

    location = /favicon.ico {
        rewrite . /favicon/favicon.ico;
    }

    location / {
        try_files \$uri \$uri/ /index.php?url=\$uri&\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_FPM}-fpm.sock;
        # fastcgi_pass 127.0.0.1:9000;
    }

    location ~* \.(html|js|css|png|jpg|jpeg|gif|ico|svg|flv|pdf|mp3|mp4|mov|txt|xml)$ {
        add_header Cache-Control 'public, no-transform';
        fastcgi_hide_header 'Set-Cookie';
        fastcgi_hide_header 'Cookie';
        add_header 'Set-Cookie' '';
        access_log off;
        expires 366d;
    }
}
" > /etc/nginx/sites-available/${DOMAIN}_http

# add http to https host
echo -e "
server {
    gzip on;
    gzip_static on;
    gunzip on;

    charset utf-8;
    client_max_body_size ${MAX_UPLOAD}M;
    disable_symlinks off;
    keepalive_timeout 60;
    server_tokens off;

    listen 80;
    listen [::]:80;

    root ${HTML_DIR}/${DOMAIN};
    server_name ${DOMAIN} www.${DOMAIN};
    index index.php index.html;

    location = /favicon.ico {
        rewrite . /favicon/favicon.ico;
    }

    location / {
        try_files \$uri \$uri/ /index.php?url=\$uri&\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_FPM}-fpm.sock;
        # fastcgi_pass 127.0.0.1:9000;
    }

    location ~* \.(html|js|css|png|jpg|jpeg|gif|ico|svg|flv|pdf|mp3|mp4|mov|txt|xml)$ {
        add_header Cache-Control 'public, no-transform';
        fastcgi_hide_header 'Set-Cookie';
        fastcgi_hide_header 'Cookie';
        add_header 'Set-Cookie' '';
        access_log off;
        expires 366d;
    }

    # return 301 https://\$host\$request_uri;
    return 301 https://${DOMAIN}\$request_uri;
}
" > /etc/nginx/sites-available/${DOMAIN}_http_redirect

# add https hosts
echo -e "
fastcgi_cache_path /tmp/domain_fcgi_${DOMAIN} keys_zone=fcgi_cache_${DOMAIN}:10m levels=1:2 inactive=600s max_size=30m use_temp_path=off;

# www to https:non-www
server {
    gzip on;
    gzip_static on;
    gzip_types text/html text/plain text/css text/xml text/js text/javascript application/javascript application/x-javascript application/json application/xml application/rss+xml image/svg+xml font/truetype font/opentype;
    gunzip on;

    charset utf-8;
    client_max_body_size 100M;
    disable_symlinks off;
    keepalive_timeout   60;
    server_tokens off;

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    root /var/www/html/${DOMAIN};
    server_name www.${DOMAIN};
    index index.php index.html;

    ssl_certificate     /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    location = /favicon.ico {
        rewrite . /favicon/favicon.ico;
    }

    location / {
        try_files \$uri \$uri/ /index.php?url=\$uri&\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_FPM}-fpm.sock;
        # fastcgi_pass 127.0.0.1:9000;
    }

    location ~* \.(html|js|css|png|jpg|jpeg|gif|ico|svg|flv|pdf|mp3|mp4|mov|txt|xml)$ {
        add_header Cache-Control 'public, no-transform';
        fastcgi_hide_header 'Set-Cookie';
        fastcgi_hide_header 'Cookie';
        add_header 'Set-Cookie' '';
        access_log off;
        expires 366d;
    }

    return 301 http://${DOMAIN}\$request_uri;
}

server {
    gzip on;
    gzip_static on;
    gzip_types text/html text/plain text/css text/xml text/js text/javascript application/javascript application/x-javascript application/json application/xml application/rss+xml image/svg+xml font/truetype font/opentype;
    gunzip on;

    charset utf-8;
    client_max_body_size 100M;
    disable_symlinks off;
    keepalive_timeout 60;

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    root /var/www/html/${DOMAIN};
    server_name ${DOMAIN};
    index index.php index.html;

    error_log /var/log/${DOMAIN}_error.log error;
    access_log /var/log/${DOMAIN}_access.log combined;

    ssl_certificate     /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location = /favicon.ico {
        rewrite . /favicon/favicon.ico;
    }

    location ~ /(Cache|cache|vendor|sql|install|.git) {
        deny all;
        return 404;
    }

    location /media {
        location ~ \.php$ {return 403;}
    }

    location / {
        proxy_cache my_cache;
        # Get file or folder or error
        # try_files \$uri \$uri/ =404;

        # Get file or folder or redirect uri to url param in index.php
        try_files \$uri \$uri/ /index.php?url=\$uri&\$args;
    }

    location ~ \.php$ {
        # Php-fpm
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_FPM}-fpm.sock;

        # Php-fpm sockets
        # fastcgi_param HTTP_PROXY "";
        # fastcgi_pass 127.0.0.1:9000;
        # fastcgi_index index.php;
        # include fastcgi_params;

        # Fast cgi cache
        set \$no_cache 0;
        if (\$request_method = POST) { set \$no_cache 1; }
        if (\$request_uri ~* '/(panel/|admin/|login.php|register.php|password.php|activate.php)') { set \$no_cache 1; }
        # Nonsens
        # if (\$query_string != '') { set \$no_cache 1; }
        # if (\$http_cookie = 'PHPSESSID') { set \$no_cache 1; }

        # enable, disable
        fastcgi_cache_bypass \$no_cache;
        fastcgi_no_cache \$no_cache;
        # settings
        fastcgi_cache fcgi_cache_${DOMAIN};
        fastcgi_cache_key '\$scheme\$request_method\$host\$request_uri\$is_args\$args\$content_length\$cookie_PHPSESSID';
        fastcgi_cache_valid 200 301 302 404 15m;
        fastcgi_cache_min_uses 3;
        fastcgi_cache_lock on;
        add_header X-Cache-Status \$upstream_cache_status;
    }

    location ~* \.(html|js|css|png|jpg|jpeg|gif|ico|svg|flv|pdf|mp3|mp4|mov|txt|xml|tar|mid|midi|wav|bmp|rtf)$ {
        add_header Cache-Control 'public, no-transform';
        fastcgi_hide_header 'Set-Cookie';
        fastcgi_hide_header 'Cookie';
        add_header 'Set-Cookie' '';
        log_not_found off;
        access_log off;
        expires 366d;
    }

    # location /produkt/dnia {
    #   return 404;
    # }
    # rewrite ^/kategoria/menu$ /menu permanent;
}
" > /etc/nginx/sites-available/${DOMAIN}_https

echo "Disabling ---> redirect host if exists"
# disable vhost http_redirect
if [ -f /etc/nginx/sites-enabled/${DOMAIN}_http_redirect ]; then
    rm /etc/nginx/sites-enabled/${DOMAIN}_http_redirect
fi

echo "Enabling ---> site virtualhost"
# enable http hosts (for certbot)
if [ ! -f /etc/nginx/sites-enabled/${DOMAIN}_http ]; then
    ln -s /etc/nginx/sites-available/${DOMAIN}_http /etc/nginx/sites-enabled/
fi

# restart nginx
sudo nginx -t
sudo service nginx restart

# backup certs
tar -czvpf "certs-$(date '+%Y-%m-%d-%H-%M-%S').tar.gz" /etc/letsencrypt

# create ssl
echo "Certbot deleting ---> old ${DOMAIN} certificate"
certbot delete --noninteractive --cert-name ${DOMAIN}

if [ -d /etc/letsencrypt/live/${DOMAIN} ]; then
    echo "Certbot deleting ---> cert directory /etc/letsencrypt/live/${DOMAIN}"
    rm -rf /etc/letsencrypt/live/${DOMAIN}
fi

if [ -d /etc/letsencrypt/archive/${DOMAIN} ]; then
    echo "Certbot deleting ---> cert directory /etc/letsencrypt/archive/${DOMAIN}"
    rm -rf /etc/letsencrypt/archive/${DOMAIN}
fi

if [ -f /etc/letsencrypt/renewal/${DOMAIN}.conf ]; then
    echo "Certbot deleting ---> cert conf /etc/letsencrypt/renewal/${DOMAIN}.conf"
    rm /etc/letsencrypt/renewal/${DOMAIN}.conf
fi

echo "Creating ---> ${DOMAIN} ssl certificate"
certbot certonly --noninteractive --agree-tos --email ${EMAIL} --expand --webroot --webroot-path ${HTML_DIR}/${DOMAIN} -d ${DOMAIN} -d www.${DOMAIN}

if [ ! -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]; then
    echo ""
    echo "!!! Error ssl public cert or can not create ssl certificate !!!"
    echo ""
    exit 1
fi

if [ ! -f /etc/letsencrypt/live/${DOMAIN}/privkey.pem ]; then
    echo ""
    echo "!!! Error ssl private cert or can not create ssl certificate !!!"
    echo ""
    exit 1
fi

echo "Certs has been created"
# disable http host
if [ -f /etc/nginx/sites-enabled/${DOMAIN}_http ]; then
    rm /etc/nginx/sites-enabled/${DOMAIN}_http
fi

echo "I turn on the virtual host http_redirect"
# enable redirect, https
if [ ! -f /etc/nginx/sites-enabled/${DOMAIN}_http_redirect ]; then
    ln -s /etc/nginx/sites-available/${DOMAIN}_http_redirect /etc/nginx/sites-enabled/
fi

echo "I turn on the virtual host https"
if [ ! -f /etc/nginx/sites-enabled/${DOMAIN}_https ]; then
    ln -s /etc/nginx/sites-available/${DOMAIN}_https /etc/nginx/sites-enabled/
fi

echo "Permissions: ${HTML_DIR}/${DOMAIN}"
# rights
chown -R ${CHOWN_USER}:www-data ${HTML_DIR}/${DOMAIN}
chmod -R 2775 ${HTML_DIR}/${DOMAIN}
chmod -R g+s ${HTML_DIR}/${DOMAIN}

# Show owners
ls -al ${HTML_DIR}/${DOMAIN}

# test config
sudo nginx -t
sudo service nginx restart

echo "[OK]"
