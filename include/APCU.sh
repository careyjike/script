#!/bin/bash

Install_APCU() {
  pushd ${Pwd}/src

  phpExtensionDir=`${php_install_dir}/bin/php-config --extension-dir`
  if [ "`${php_install_dir}/bin/php -r 'echo PHP_VERSION;' | awk -F. '{print $1}'`" == '7' ]; then
  	src_url=http://pecl.php.net/get/apcu-${apcu_for_php7_version}.tgz && wget -c --tries=6 $src_url
    tar xzf apcu-${apcu_for_php7_version}.tgz
    pushd apcu-${apcu_for_php7_version}
  else
  	src_url=http://pecl.php.net/get/apcu-${apcu_version}.tgz && wget -c --tries=6 $src_url
    tar xzf apcu-${apcu_version}.tgz
    pushd apcu-${apcu_version}
  fi

  ${php_install_dir}/bin/phpize
  ./configure --with-php-config=${php_install_dir}/bin/php-config
  make -j ${THREAD} && make install
  if [ -f "${phpExtensionDir}/apcu.so" ]; then
    cat > ${php_install_dir}/etc/php.d/ext-apcu.ini << EOF
[apcu]
extension=apcu.so
apc.enabled=1
apc.shm_size=32M
apc.ttl=7200
apc.enable_cli=1
EOF
    /bin/cp apc.php ${wwwroot_dir}/default
    echo "${CSUCCESS}APCU module installed successfully! ${CEND}"
    popd
    rm -rf apcu-${apcu_for_php7_version} apcu-${apcu_version} package.xml
  else
    echo "${CFAILURE}APCU module install failed, Please contact the author! ${CEND}"
  fi
  popd
}