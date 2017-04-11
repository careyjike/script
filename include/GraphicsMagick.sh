#!/bin/bash
Install_GraphicsMagick() {
  pushd ${Pwd}/src
  src_url=http://downloads.sourceforge.net/project/graphicsmagick/graphicsmagick/${GraphicsMagick_version}/GraphicsMagick-${GraphicsMagick_version}.tar.gz && wget -c --tries=6 $src_url
  tar xzf GraphicsMagick-${GraphicsMagick_version}.tar.gz
  pushd GraphicsMagick-${GraphicsMagick_version}
  ./configure --prefix=/usr/local/graphicsmagick --enable-shared --enable-static
  make -j ${THREAD} && make install
  popd;popd
}

Install_php-gmagick() {
  pushd ${Pwd}/src
  if [ -e "${php_install_dir}/bin/phpize" ]; then
    phpExtensionDir=`${php_install_dir}/bin/php-config --extension-dir`
    if [ "`${php_install_dir}/bin/php -r 'echo PHP_VERSION;' | awk -F. '{print $1}'`" == '7' ]; then
      src_url=https://pecl.php.net/get/gmagick-${gmagick_for_php7_version}.tgz && wget -c --tries=6 $src_url
      tar xzf gmagick-${gmagick_for_php7_version}.tgz
      pushd gmagick-${gmagick_for_php7_version}
    else
      src_url=http://pecl.php.net/get/gmagick-${gmagick_version}.tgz && wget -c --tries=6 $src_url
      tar xzf gmagick-${gmagick_version}.tgz
      pushd gmagick-${gmagick_version}
    fi
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
    ${php_install_dir}/bin/phpize
    ./configure --with-php-config=${php_install_dir}/bin/php-config --with-gmagick=/usr/local/graphicsmagick
    make -j ${THREAD} && make install
    popd
    if [ -f "${phpExtensionDir}/gmagick.so" ]; then
      echo 'extension=gmagick.so' > ${php_install_dir}/etc/php.d/ext-gmagick.ini
      echo -e "${CSUCCESSFUL}PHP gmagick module installed successfully! ${CEND}"
    else
      echo -e "${CFAIL}PHP gmagick module install failed, Please contact the author! ${CEND}"
    fi
  fi
  popd
}