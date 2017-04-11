#!/bin/bash


Install_memcached() {
  pushd ${Pwd}/src
  src_url=http://www.memcached.org/files/memcached-${memcached_version}.tar.gz &&  wget -c --tries=6 $src_url

  # memcached server
  id -u memcached >/dev/null 2>&1
  [ $? -ne 0 ] && useradd -M -s /sbin/nologin memcached

  tar xzf memcached-${memcached_version}.tar.gz
  pushd memcached-${memcached_version}
  [ ! -d "${memcached_install_dir}" ] && mkdir -p ${memcached_install_dir}
  ./configure --prefix=${memcached_install_dir}
  make -j ${THREAD} && make install
  popd
  if [ -d "${memcached_install_dir}/include/memcached" ]; then
    echo "${CSUCCESSFUL}memcached installed successfully! ${CEND}"
    rm -rf memcached-${memcached_version}
    ln -s ${memcached_install_dir}/bin/memcached /usr/bin/memcached
    /bin/cp ../init.d/memcached /etc/init.d/memcached; chmod +x /etc/init.d/memcached; chkconfig --add memcached; chkconfig memcached on    sed -i "s@/usr/local/memcached@${memcached_install_dir}@g" /etc/init.d/memcached
    let memcachedCache="${Mem}/8"
    [ -n "$(grep 'CACHESIZE=' /etc/init.d/memcached)" ] && sed -i "s@^CACHESIZE=.*@CACHESIZE=${memcachedCache}@" /etc/init.d/memcached
    [ -n "$(grep 'start_instance default 256;' /etc/init.d/memcached)" ] && sed -i "s@start_instance default 256;@start_instance default ${memcachedCache};@" /etc/init.d/memcached
    service memcached start
    rm -rf memcached-${memcached_version}
  else
    rm -rf ${memcached_install_dir}
    echo "${CFAIL}memcached install failed, Please contact the author! ${CEND}"
    kill -9 $$
  fi
  popd
}

Install_php-memcache() {
  pushd ${Pwd}/src
  if [ -e "${php_install_dir}/bin/phpize" ]; then
    phpExtensionDir=$(${php_install_dir}/bin/php-config --extension-dir)
    # php memcache extension
    if [ "$(${php_install_dir}/bin/php -r 'echo PHP_VERSION;' | awk -F. '{print $1}')" == '7' ]; then
      git clone https://github.com/websupport-sk/pecl-memcache.git
      cd pecl-memcache
      # src_url=https://codeload.github.com/websupport-sk/pecl-memcache/zip/php7 && wget -c --tries=6 $src_url
      # tar xzf pecl-memcache-php7.tgz
      # pushd pecl-memcache-php7
    else
      src_url=http://pecl.php.net/get/memcache-${memcache_pecl_version}.tgz && wget -c --tries=6 $src_url
      tar xzf memcache-${memcache_pecl_version}.tgz
      pushd memcache-${memcache_pecl_version}
    fi
    ${php_install_dir}/bin/phpize
    ./configure --with-php-config=${php_install_dir}/bin/php-config
    make -j ${THREAD} && make install
    popd
    if [ -f "${phpExtensionDir}/memcache.so" ]; then
      echo "extension=memcache.so" > ${php_install_dir}/etc/php.d/ext-memcache.ini
      echo "${CSUCCESSFUL}PHP memcache module installed successfully! ${CEND}"
      rm -rf pecl-memcache-php7 memcache-${memcache_pecl_version}
    else
      echo "${CFAIL}PHP memcache module install failed, Please contact the author! ${CEND}"
    fi
  fi
  popd
}

Install_php-memcached() {
  pushd ${Pwd}/src
  if [ -e "${php_install_dir}/bin/phpize" ]; then
    phpExtensionDir=$(${php_install_dir}/bin/php-config --extension-dir)
    # php memcached extension
    src_url=https://launchpad.net/libmemcached/1.0/${libmemcached_version}/+download/libmemcached-${libmemcached_version}.tar.gz && wget -c --tries=6 --no-cache-certificate $src_url
    tar xzf libmemcached-${libmemcached_version}.tar.gz
    pushd libmemcached-${libmemcached_version}
    yum -y install cyrus-sasl-devel
    ./configure --with-memcached=${memcached_install_dir}
    make -j ${THREAD} && make install
    popd
    rm -rf libmemcached-${libmemcached_version}

    if [ "$(${php_install_dir}/bin/php -r 'echo PHP_VERSION;' | awk -F. '{print $1}')" == '7' ]; then
      src_url=https://pecl.php.net/get/memcached-${memcached_pecl_php7_version}.tgz && wget -c --tries=6 $src_url
      tar xzf memcached-${memcached_pecl_php7_version}.tgz
      pushd memcached-${memcached_pecl_php7_version}
    else
      src_url=http://pecl.php.net/get/memcached-${memcached_pecl_version}.tgz && wget -c --tries=6 $src_url
      tar xzf memcached-${memcached_pecl_version}.tgz
      pushd memcached-${memcached_pecl_version}
    fi
    ${php_install_dir}/bin/phpize
    ./configure --with-php-config=${php_install_dir}/bin/php-config
    make -j ${THREAD} && make install
    popd
    if [ -f "${phpExtensionDir}/memcached.so" ]; then
      cat > ${php_install_dir}/etc/php.d/ext-memcached.ini << EOF
extension=memcached.so
memcached.use_sasl=1
EOF
      echo "${CSUCCESSFUL}PHP memcached module installed successfully! ${CEND}"
      rm -rf memcached-${memcached_pecl_version} memcached-${memcached_pecl_php7_version}
    else
      echo "${CFAIL}PHP memcached module install failed, Please contact the author! ${CEND}"
    fi
  fi
  popd
}
