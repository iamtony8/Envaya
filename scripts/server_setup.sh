#!/bin/bash
# ubuntu 10.04

# configures envaya services on ubuntu, assuming prerequisites already installed

INSTALL_DIR=$1
if [ ! $1  ]; then
  SCRIPT_DIR=$(cd `dirname $0` && pwd)
  INSTALL_DIR=`dirname $SCRIPT_DIR`
fi
echo "INSTALL_DIR is $INSTALL_DIR"

function add_php_settings {
cat <<EOF >> /etc/php5/fpm/php.ini

; envaya custom settings
error_reporting = E_ALL & ~E_DEPRECATED & ~E_NOTICE & ~E_USER_NOTICE
date.timezone = "UTC"
zlib.output_compression = 1
expose_php = 0
upload_max_filesize = "12M"
post_max_size = "12M"

EOF

cat <<EOF >> /etc/php5/cli/php.ini

; envaya custom settings
date.timezone = "UTC"
EOF
}

if ! grep -q envaya /etc/php5/fpm/php.ini ; then add_php_settings; fi

mkdir -p /etc/nginx/ssl
chown www-data:www-data /etc/nginx/ssl
chmod 700 /etc/nginx/ssl

mkdir -p /var/nginx/cache
chmod 777 /var/nginx/cache

mkdir -p /var/elgg-data
chmod 777 /var/elgg-data
touch /var/elgg-data/last_error_time
chmod 777 /var/elgg-data/last_error_time

cat <<EOF > /etc/php5/fpm/php5-fpm.conf

[global]
pid = /var/run/php5-fpm.pid
error_log = /var/log/php5-fpm.log
log_level = notice
;emergency_restart_threshold = 0
;emergency_restart_interval = 0
;process_control_timeout = 0
;daemonize = yes

[www]
listen = 127.0.0.1:9000
;listen.backlog = -1
;listen.allowed_clients = 127.0.0.1
;listen.owner = www-data
;listen.group = www-data
;listen.mode = 0666
user = www-data
group = www-data

pm = dynamic
pm.max_children = 20
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500
pm.status_path = /status.php
;ping.path = /ping
;ping.response = pong
;request_terminate_timeout = 0
;request_slowlog_timeout = 0
;slowlog = /var/log/php5-fpm.log.slow
;rlimit_files = 1024
;rlimit_core = 0
;chroot = 
;chdir = /var/www
;catch_workers_output = yes
 
; Pass environment variables like LD_LIBRARY_PATH. All \$VARIABLEs are taken from
; the current environment.
; Default Value: clean env
;env[HOSTNAME] = \$HOSTNAME
;env[PATH] = /usr/local/bin:/usr/bin:/bin
;env[TMP] = /tmp
;env[TMPDIR] = /tmp
;env[TEMP] = /tmp

;php_admin_value[sendmail_path] = /usr/sbin/sendmail -t -i -f www@my.domain.com
;php_flag[display_errors] = off
;php_admin_value[error_log] = /var/log/fpm-php.www.log
;php_admin_flag[log_errors] = on
;php_admin_value[memory_limit] = 32M

EOF

cat <<EOF > /etc/nginx/sites-available/default

server {
    listen   80;
    include /etc/nginx/envaya.conf;

    location ~ \.php
    {
       include /etc/nginx/fastcgi_params;
    }
}

EOF

cat <<EOF > /etc/nginx/sites-available/ssl

server {
    listen 443;
    server_name envaya.org;
    ssl on;
    ssl_certificate /etc/nginx/ssl/envaya_combined.crt;
    ssl_certificate_key /etc/nginx/ssl/envaya.org.key;
    include /etc/nginx/envaya.conf;

    location ~ \.php
    {
       fastcgi_param HTTPS on;
       include /etc/nginx/fastcgi_params;
    }      
}

EOF


cat <<EOF > /etc/nginx/fastcgi_params

fastcgi_pass 127.0.0.1:9000;
fastcgi_param SCRIPT_FILENAME $INSTALL_DIR/www/\$fastcgi_script_name;
fastcgi_param PATH_INFO \$fastcgi_script_name;

fastcgi_cache envaya;
fastcgi_no_cache \$cookie_envaya \$arg_nocache;
fastcgi_cache_bypass \$cookie_envaya \$arg_nocache;
fastcgi_cache_key "\$scheme:\$host:\$request_uri:\$cookie_lang:\$cookie_view:\$geoip_country_code:\$http_accept_encoding";
fastcgi_cache_valid any 1m;
fastcgi_cache_use_stale error timeout http_500;

fastcgi_param  QUERY_STRING       \$query_string;
fastcgi_param  REQUEST_METHOD     \$request_method;
fastcgi_param  CONTENT_TYPE       \$content_type;
fastcgi_param  CONTENT_LENGTH     \$content_length;

fastcgi_param  SCRIPT_NAME        \$fastcgi_script_name;
fastcgi_param  REQUEST_URI        \$request_uri;
fastcgi_param  DOCUMENT_URI       \$document_uri;
fastcgi_param  DOCUMENT_ROOT      \$document_root;
fastcgi_param  SERVER_PROTOCOL    \$server_protocol;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/\$nginx_version;

fastcgi_param  REMOTE_ADDR        \$remote_addr;
fastcgi_param  REMOTE_PORT        \$remote_port;
fastcgi_param  SERVER_ADDR        \$server_addr;
fastcgi_param  SERVER_PORT        \$server_port;
fastcgi_param  SERVER_NAME        \$server_name;

fastcgi_param  GEOIP_COUNTRY_CODE \$geoip_country_code;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param  REDIRECT_STATUS    200;

EOF

cat <<EOF > /etc/nginx/envaya.conf

    root $INSTALL_DIR/www;
    access_log  /var/log/nginx/access.log combined_time;
    client_max_body_size 10m;
    client_body_timeout 118;
    send_timeout 124;
    
    location / {
        index  index.php;
        rewrite ^(.*)\$ /index.php\$1 last;
    }
    
    location /status.nginx
    {
        stub_status on;
        access_log   off;
    }    
       
    location /_media/ {
        expires 1y;
        gzip_types application/x-javascript text/css;
        gzip on;
        gzip_min_length 1000;
    }    

EOF

cat <<EOF > /etc/nginx/nginx.conf
user www-data;
worker_processes 2;

error_log  /var/log/nginx/error.log;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
    # multi_accept on;
}

http {
    include       /etc/nginx/mime.types;

    fastcgi_cache_path /var/nginx/cache/envaya levels=2:2 keys_zone=envaya:10m;
    
    geoip_country /usr/share/GeoIP/GeoIP.dat;
    
    access_log  /var/log/nginx/access.log;
    
    log_format combined_time '\$remote_addr - \$remote_user [\$time_local]  '
                    '"\$request" \$status \$body_bytes_sent '
                    '"\$http_referer" "\$http_user_agent" \$request_time';    

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  15;
    tcp_nodelay        on;

    gzip  on;
    gzip_disable "MSIE [1-6]\.(?!.*SV1)";

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}

EOF

cp $INSTALL_DIR/scripts/config/cups-pdf.conf /etc/cups/
$INSTALL_DIR/scripts/server_kestrel_setup.sh

cat $INSTALL_DIR/scripts/init.d/queueRunner | sed -e "s,APP_HOME=\"\",APP_HOME=\"$INSTALL_DIR\",g" > /etc/init.d/queueRunner

chmod 755 /etc/init.d/queueRunner
update-rc.d queueRunner defaults 96
/etc/init.d/queueRunner start

cat $INSTALL_DIR/scripts/init.d/phpCron | sed -e "s,APP_HOME=\"\",APP_HOME=\"$INSTALL_DIR\",g" > /etc/init.d/phpCron

chmod 755 /etc/init.d/phpCron
update-rc.d phpCron defaults 97
/etc/init.d/phpCron start

/etc/init.d/nginx start
/etc/init.d/nginx reload
/etc/init.d/php5-fpm start
