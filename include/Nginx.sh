#!/bin/bash


Install_nginx() {
  pushd ${Pwd}/src
  src_url=http://nginx.org/download/nginx-${nginx_version}.tar.gz && wget -c --tries=6 $src_url
  src_url=https://ftp.pcre.org/pub/pcre/pcre-${pcre_version}.tar.gz && wget -c --tries=6 --no-check-certificate $src_url
  src_url=https://www.openssl.org/source/openssl-${openssl_version}.tar.gz && wget -c --tries=6 --no-check-certificate $src_url
  src_url=http://prdownloads.sourceforge.net/libpng/zlib-${zlib_version}.tar.gz && wget -c --tries=6 $src_url

  tar zxf pcre-${pcre_version}.tar.gz
  tar zxf openssl-${openssl_version}.tar.gz
  tar zxf zlib-${zlib_version}.tar.gz
  tar zxf nginx-${nginx_version}.tar.gz && pushd nginx-$nginx_version

  id -u $run_user >/dev/null 2>&1
  [ $? -ne 0 ] && useradd -M -s /sbin/nologin $run_user
  if [ ! -d ${data_dir} ]; then mkdir -p ${data_dir}/{wwwlogs,wwwroot}; fi
  # Modify Nginx version
  #sed -i 's@#define NGINX_VERSION.*$@#define NGINX_VERSION      "1.2"@' src/core/nginx.h
  #sed -i 's@#define NGINX_VER.*NGINX_VERSION$@#define NGINX_VER          "Linuxeye/" NGINX_VERSION@' src/core/nginx.h
  #sed -i 's@Server: nginx@Server: linuxeye@' src/http/ngx_http_header_filter_module.c

  # close debug
  sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc

  [ ! -d "$nginx_install_dir" ] && mkdir -p $nginx_install_dir
  ./configure --prefix=$nginx_install_dir --user=$run_user --group=$run_user --with-http_stub_status_module  --with-http_ssl_module --with-http_gzip_static_module --with-http_realip_module --with-http_flv_module --with-http_mp4_module --with-openssl=../openssl-$openssl_version --with-pcre=../pcre-$pcre_version --with-zlib=../zlib-$zlib_version --with-pcre-jit --with-ld-opt='-ljemalloc'
  make -j ${THREAD} && make install

  if [ -e "$nginx_install_dir/conf/nginx.conf" ]; then
    popd
    rm -rf nginx-$nginx_version
    echo "${CSUCCESSFUL} Nginx installed successfully! ${CEND}"
  else
    rm -rf $nginx_install_dir
    echo "${CFAIL} Nginx install failed, Please Contact the author! ${CEND}"
    kill -9 $$
  fi
  popd
  [ -z "`grep ^'export PATH=' /etc/profile`" ] && echo "export PATH=$nginx_install_dir/sbin:\$PATH" >> /etc/profile
  . /etc/profile

  # nginx service
  cat > /etc/init.d/nginx << EOF
#!/bin/sh
#
# nginx - this script starts and stops the nginx daemon
#
# chkconfig:   - 85 15
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /usr/local/nginx/conf/nginx.conf
# pidfile:     /var/run/nginx.pid

nginx="/usr/local/nginx/sbin/nginx"

NGINX_CONF_FILE="/usr/local/nginx/conf/nginx.conf"

start() {
  [ -x \$nginx ] || exit 5
  [ -f \$NGINX_CONF_FILE ] || exit 6
  echo -e "Starting nginx...... "
  \$nginx
}

stop() {
  echo -e "Stopping nginx...... "
  \$nginx -s stop
}

restart() {
  stop
  sleep 1
  start
}

reload() {
  echo -e " Reload nginx...... "
  \$nginx -s reload
}

force_reload() {
  restart
}

configtest() {
  \$nginx -t
}

case "\$1" in
  start)
    \$1
    ;;
  stop)
    \$1
    ;;
  restart|configtest)
    \$1
    ;;
  reload)
    \$1
    ;;
  *)
    echo $"Usage: \$0 {start|stop|restart|reload|configtest}"
    exit 2
esac
EOF
  chmod +x /etc/init.d/nginx && chkconfig --add nginx;chkconfig nginx on
  sed -i "s@/usr/local/nginx@$nginx_install_dir@g" /etc/init.d/nginx
  # nginx.conf
  cat > ${nginx_install_dir}/conf/nginx.conf << EOF
user $run_user $run_user;
worker_processes $(cat /proc/cpuinfo | grep processor | wc -l);

error_log ${data_dir}/logs/error_nginx.log crit;
pid /var/run/nginx.pid;
worker_rlimit_nofile 51200;

events {
  use epoll;
  worker_connections 51200;
  multi_accept on;
}

http {
  include mime.types;
  default_type application/octet-stream;
  server_names_hash_bucket_size 128;
  client_header_buffer_size 32k;
  large_client_header_buffers 4 32k;
  client_max_body_size 1024m;
  client_body_buffer_size 10m;
  sendfile on;
  tcp_nopush on;
  keepalive_timeout 120;
  server_tokens off;
  tcp_nodelay on;

  fastcgi_connect_timeout 300;
  fastcgi_send_timeout 300;
  fastcgi_read_timeout 300;
  fastcgi_buffer_size 64k;
  fastcgi_buffers 4 64k;
  fastcgi_busy_buffers_size 128k;
  fastcgi_temp_file_write_size 128k;
  fastcgi_intercept_errors on;

  #Gzip Compression
  gzip on;
  gzip_buffers 16 8k;
  gzip_comp_level 6;
  gzip_http_version 1.1;
  gzip_min_length 256;
  gzip_proxied any;
  gzip_vary on;
  gzip_types
    text/xml application/xml application/atom+xml application/rss+xml application/xhtml+xml image/svg+xml
    text/javascript application/javascript application/x-javascript
    text/x-json application/json application/x-web-app-manifest+json
    text/css text/plain text/x-component
    font/opentype application/x-font-ttf application/vnd.ms-fontobject
    image/x-icon;
  gzip_disable "MSIE [1-6]\.(?!.*SV1)";

  #If you have a lot of static files to serve through Nginx then caching of the files' metadata (not the actual files' contents) can save some latency.
  open_file_cache max=1000 inactive=20s;
  open_file_cache_valid 30s;
  open_file_cache_min_uses 2;
  open_file_cache_errors on;

######################## default ############################
  server {
  listen 80;
  server_name _;
  access_log ${data_dir}/logs/access_nginx.log combined;
  root ${data_dir}/wwwroot;
  index index.html index.htm index.php;
  location /nginx_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
    }
  location ~ [^/]\.php(/|$) {
    #fastcgi_pass remote_php_ip:9000;
    fastcgi_pass unix:/dev/shm/php-cgi.sock;
    fastcgi_index index.php;
    include fastcgi.conf;
    }
  location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|mp4|ico)$ {
    expires 30d;
    access_log off;
    }
  location ~ .*\.(js|css)?$ {
    expires 7d;
    access_log off;
    }
  location ~ /\.ht {
    deny all;
    }
  }

########################## vhost #############################
  include vhost/*.conf;
}
EOF
  # nginx proxy.conf
  cat > ${nginx_install_dir}/conf/proxy.conf << EOF
proxy_connect_timeout 300s;
proxy_send_timeout 900;
proxy_read_timeout 900;
proxy_buffer_size 32k;
proxy_buffers 4 64k;
proxy_busy_buffers_size 128k;
proxy_redirect off;
proxy_hide_header Vary;
proxy_set_header Accept-Encoding '';
proxy_set_header Referer \$http_referer;
proxy_set_header Cookie \$http_cookie;
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
EOF
}