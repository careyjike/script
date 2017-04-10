#!/bin/bash


Install_Nginx() {
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
  cp ${Pwd}/init.d/nginx /etc/init.d/nginx && chmod +x /etc/init.d/nginx && chkconfig --add nginx;chkconfig nginx on
  sed -i "s@/usr/local/nginx@${nginx_install_dir}@g" /etc/init.d/nginx

  # nginx.conf
  cp ${Pwd}/conf/nginx.conf ${nginx_install_dir}/conf/nginx.conf
  sed -i "s@/data/wwwroot/default@$wwwroot_dir/default@" $nginx_install_dir/conf/nginx.conf
  sed -i "s@/data/wwwlogs@$wwwlogs_dir@g" $nginx_install_dir/conf/nginx.conf
  sed -i "s@^user www www@user $run_user $run_user@" $nginx_install_dir/conf/nginx.conf

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
  # logrotate nginx log
  cat > /etc/logrotate.d/nginx << EOF
$wwwlogs_dir/*nginx.log {
  daily
  rotate 5
  missingok
  dateext
  compress
  notifempty
  sharedscripts
  postrotate
    [ -e /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
  endscript
}
EOF
  ldconfig
  /etc/init.d/nginx start
}