#!/bin/bash


Install_redis-server() {
  pushd ${Pwd}/src
  src_url=http://download.redis.io/releases/redis-${redis_version}.tar.gz && wget -c --tries=6 $src_url
  tar xzf redis-${redis_version}.tar.gz
  pushd redis-${redis_version}
  if [ "$OS_BIT" == '32' ]; then
    sed -i '1i\CFLAGS= -march=i686' src/Makefile
    sed -i 's@^OPT=.*@OPT=-O2 -march=i686@' src/.make-settings
  fi
  make -j ${THREAD}
  if [ -f "src/redis-server" ]; then
    mkdir -p ${redis_install_dir}/{bin,etc,var}
    /bin/cp src/{redis-benchmark,redis-check-aof,redis-check-rdb,redis-cli,redis-sentinel,redis-server} ${redis_install_dir}/bin/
    /bin/cp redis.conf ${redis_install_dir}/etc/
    ln -s ${redis_install_dir}/bin/* /usr/local/bin/
    sed -i 's@pidfile.*@pidfile /var/run/redis.pid@' ${redis_install_dir}/etc/redis.conf
    sed -i "s@logfile.*@logfile ${redis_install_dir}/var/redis.log@" ${redis_install_dir}/etc/redis.conf
    sed -i "s@^dir.*@dir ${redis_install_dir}/var@" ${redis_install_dir}/etc/redis.conf
    sed -i 's@daemonize no@daemonize yes@' ${redis_install_dir}/etc/redis.conf
    sed -i "s@^# bind 127.0.0.1@bind 127.0.0.1@" ${redis_install_dir}/etc/redis.conf
    redis_maxmemory=`expr $Mem / 8`000000
    [ -z "`grep ^maxmemory ${redis_install_dir}/etc/redis.conf`" ] && sed -i "s@maxmemory <bytes>@maxmemory <bytes>\nmaxmemory `expr $Mem / 8`000000@" ${redis_install_dir}/etc/redis.conf
    echo "${CSUCCESSFUL}Redis-server installed successfully! ${CEND}"
    popd
    id -u redis >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -s /sbin/nologin redis
    chown -R redis:redis ${redis_install_dir}/var
    /bin/cp ../init.d/redis-server /etc/init.d/redis-server

    cc start-stop-daemon.c -o /sbin/start-stop-daemon
    chkconfig --add redis-server
    chkconfig redis-server on

    sed -i "s@/usr/local/redis@${redis_install_dir}@g" /etc/init.d/redis-server
    #[ -z "`grep 'vm.overcommit_memory' /etc/sysctl.conf`" ] && echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
    #sysctl -p
    service redis-server start
  else
    rm -rf ${redis_install_dir}
    echo "${CFAIL}Redis-server install failed, Please contact the author! ${CEND}"
    kill -9 $$
  fi
  popd
}

Install_php-redis() {
  pushd ${Pwd}/src
  if [ -e "${php_install_dir}/bin/phpize" ]; then
    phpExtensionDir=`${php_install_dir}/bin/php-config --extension-dir`
    if [ "`${php_install_dir}/bin/php -r 'echo PHP_VERSION;' | awk -F. '{print $1}'`" == '7' ]; then
    	src_url=http://pecl.php.net/get/redis-${redis_pecl_for_php7_version}.tgz && wget -c --tries=6 $src_url
      tar xzf redis-${redis_pecl_for_php7_version}.tgz
      pushd redis-${redis_pecl_for_php7_version}
    else
    	src_url=http://pecl.php.net/get/redis-${redis_pecl_version}.tgz && wget -c --tries=6 $src_url
      tar xzf redis-$redis_pecl_version.tgz
      pushd redis-$redis_pecl_version
    fi
    ${php_install_dir}/bin/phpize
    ./configure --with-php-config=${php_install_dir}/bin/php-config
    make -j ${THREAD} && make install
    if [ -f "${phpExtensionDir}/redis.so" ]; then
      echo 'extension=redis.so' > ${php_install_dir}/etc/php.d/ext-redis.ini
      echo "${CSUCCESSFUL}PHP Redis module installed successfully! ${CEND}"
      popd
    else
      echo "${CFAIL}PHP Redis module install failed, Please contact the author! ${CEND}"
    fi
  fi
  popd
}
