#!/bin/bash

Install_ZendOPcache() {
  pushd ${Pwd}/src
  src_url=https://pecl.php.net/get/zendopcache-${zendopcache_version}.tgz && wget -c --tries=6 $src_url

  phpExtensionDir=$(${php_install_dir}/bin/php-config --extension-dir)
  PHP_detail_version=$(${php_install_dir}/bin/php -r 'echo PHP_VERSION;')
  PHP_main_version=${PHP_detail_version%.*}
  if [[ "${PHP_main_version}" =~ ^5.[3-4]$ ]]; then
    tar xvf zendopcache-${zendopcache_version}.tgz
    pushd zendopcache-${zendopcache_version}
  else
    tar xvf php-${PHP_detail_version}.tar.gz
    pushd php-${PHP_detail_version}/ext/opcache
  fi

  ${php_install_dir}/bin/phpize
  ./configure --with-php-config=${php_install_dir}/bin/php-config
  make -j ${THREAD} && make install
  popd
  if [ -f "${phpExtensionDir}/opcache.so" ]; then
    # write opcache configs
    if [[ "${PHP_main_version}" =~ ^5.[3-4]$ ]]; then
      # For php 5.3 5.4
      cat > ${php_install_dir}/etc/php.d/ext-opcache.ini << EOF
[opcache]
zend_extension=${phpExtensionDir}/opcache.so
opcache.enable=1
opcache.memory_consumption=${Memory_limit}
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.save_comments=0
opcache.fast_shutdown=1
opcache.enable_cli=1
;opcache.optimization_level=0
EOF
    else
      # For php 5.5+
      cat > ${php_install_dir}/etc/php.d/ext-opcache.ini << EOF
[opcache]
zend_extension=opcache.so
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=${Memory_limit}
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=100000
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=60
opcache.save_comments=0
opcache.fast_shutdown=1
opcache.consistency_checks=0
;opcache.optimization_level=0
EOF
    fi

    echo -e  "${CSUCCESSFUL}PHP OPcache module installed successfully! ${CEND}"
  else
    echo -e "${CFAIL}PHP OPcache module install failed, Please contact the author! ${CEND}"
  fi
  popd
}