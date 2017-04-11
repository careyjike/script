#!/bin/bash

Install_Tengine() {
  pushd ${Pwd}/src
  src_url=https://ftp.pcre.org/pub/pcre/pcre-${pcre_version}.tar.gz && wget -c --tries=6 --no-check-certificate $src_url
  src_url=https://www.openssl.org/source/openssl-${openssl_version}.tar.gz && wget -c --tries=6 --no-check-certificate $src_url
  src_url=http://tengine.taobao.org/download/tengine-${tengine_version}.tar.gz && wget -c --tries=6 $src_url

  id -u $run_user >/dev/null 2>&1
  [ $? -ne 0 ] && useradd -M -s /sbin/nologin $run_user

  tar xzf pcre-$pcre_version.tar.gz
  tar xzf tengine-$tengine_version.tar.gz
  tar xzf openssl-OpenSSL_$openssl_version.tar.gz
  pushd tengine-$tengine_version
  # Modify Tengine version
  #sed -i 's@TENGINE "/" TENGINE_VERSION@"Tengine/unknown"@' src/core/nginx.h

  # close debug
  sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc

  [ ! -d "$tengine_install_dir" ] && mkdir -p $tengine_install_dir
  ./configure --prefix=$tengine_install_dir --user=$run_user --group=$run_user --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_realip_module --with-http_flv_module --with-http_mp4_module --with-http_concat_module=shared --with-http_sysguard_module=shared --with-openssl=../openssl-$openssl_version --with-pcre=../pcre-$pcre_version --with-pcre-jit --with-jemalloc $nginx_modules_options
  make -j ${THREAD} && make install
  if [ -e "$tengine_install_dir/conf/nginx.conf" ]; then
    popd
    rm -rf tengine-$tengine_version
    echo "${CSUCCESSFUL}Tengine installed successfully! ${CEND}"
  else
    rm -rf $tengine_install_dir
    echo "${CFAIL}Tengine install failed, Please Contact the author! ${CEND}"
    kill -9 $$
  fi

  [ -z "`grep ^'export PATH=' /etc/profile`" ] && echo "export PATH=$tengine_install_dir/sbin:\$PATH" >> /etc/profile
  [ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep $tengine_install_dir /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=$tengine_install_dir/sbin:\1@" /etc/profile
  . /etc/profile

  cp ${Pwd}/init.d/nginx /etc/init.d/nginx; chkconfig --add nginx; chkconfig nginx on
  sed -i "s@/usr/local/nginx@$tengine_install_dir@g" /etc/init.d/nginx

  mv $tengine_install_dir/conf/nginx.conf{,_bk}
  cp ${Pwd}/conf/nginx.conf ${tengine_install_dir}/conf/nginx.conf

  cat > $tengine_install_dir/conf/proxy.conf << EOF
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
  sed -i "s@/data/wwwroot/default@$wwwroot_dir/default@" $tengine_install_dir/conf/nginx.conf
  sed -i "s@/data/wwwlogs@$wwwlogs_dir@g" $tengine_install_dir/conf/nginx.conf
  sed -i "s@^user www www@user $run_user $run_user@" $tengine_install_dir/conf/nginx.conf
  uname -r | awk -F'.' '{if ($1$2>=39)S=0;else S=1}{exit S}' && [ -z "`grep 'reuse_port on;' $tengine_install_dir/conf/nginx.conf`" ] && sed -i "s@worker_connections 51200;@worker_connections 51200;\n    reuse_port on;@" $tengine_install_dir/conf/nginx.conf

  # worker_cpu_affinity
  sed -i "s@^worker_processes.*@worker_processes auto;\nworker_cpu_affinity auto;\ndso {\n\tload ngx_http_concat_module.so;\n\tload ngx_http_sysguard_module.so;\n}@" $tengine_install_dir/conf/nginx.conf

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
  popd
  ldconfig
  service nginx start
}
