#!/bin/bash


Install_ImageMagick() {
  pushd ${Pwd}/src
  src_url=http://mirror.checkdomain.de/imagemagick/ImageMagick-${ImageMagick_version}.tar.gz && wget -c --tries=6 $src_url
  tar xzf ImageMagick-${ImageMagick_version}.tar.gz
  pushd ImageMagick-${ImageMagick_version}
  ./configure --prefix=/usr/local/imagemagick --enable-shared --enable-static
  make -j ${THREAD} && make install
  popd;popd
}

Install_php-imagick() {
  pushd ${Pwd}/src
  if [ -e "${php_install_dir}/bin/phpize" ]; then
    phpExtensionDir=`${php_install_dir}/bin/php-config --extension-dir`
    if [ "`${php_install_dir}/bin/php -r 'echo PHP_VERSION;' | awk -F. '{print $1"."$2}'`" == '5.3' ]; then
      src_url=https://pecl.php.net/get/imagick-${imagick_for_php53_version}.tgz  && wget -c --tries=6 $src_url
      tar xzf imagick-${imagick_for_php53_version}.tgz
      pushd imagick-${imagick_for_php53_version}
    else
      src_url=http://pecl.php.net/get/imagick-${imagick_version}.tgz && wget -c -tries=6 $src_url
      tar xzf imagick-${imagick_version}.tgz
      pushd imagick-${imagick_version}
    fi
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
    ${php_install_dir}/bin/phpize
    ./configure --with-php-config=${php_install_dir}/bin/php-config --with-imagick=/usr/local/imagemagick
    make -j ${THREAD} && make install
    popd
    if [ -f "${phpExtensionDir}/imagick.so" ]; then
      echo 'extension=imagick.so' > ${php_install_dir}/etc/php.d/ext-imagick.ini
      echo -e "${CSUCCESSFUL}PHP imagick module installed successfully! ${CEND}"
    else
      echo -e "${CFAIL}PHP imagick module install failed, Please contact the author! ${CEND}"
    fi
  fi
  popd
}