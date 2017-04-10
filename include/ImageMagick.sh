#!/bin/bash


Install_ImageMagick() {
  pushd ${Pwd}/src
  tar xzf ImageMagick-${ImageMagick_version}.tar.gz
  pushd ImageMagick-${ImageMagick_version}
  ./configure --prefix=/usr/local/imagemagick --enable-shared --enable-static
  make -j ${THREAD} && make install
  popd
  rm -rf ImageMagick-${ImageMagick_version}
  popd
}

Install_php-imagick() {
  pushd ${Pwd}/src
  if [ -e "${php_install_dir}/bin/phpize" ]; then
    phpExtensionDir=`${php_install_dir}/bin/php-config --extension-dir`
    if [ "`${php_install_dir}/bin/php -r 'echo PHP_VERSION;' | awk -F. '{print $1"."$2}'`" == '5.3' ]; then
      tar xzf imagick-${imagick_for_php53_version}.tgz
      pushd imagick-${imagick_for_php53_version}
    else
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
      echo "${CSUCCESS}PHP imagick module installed successfully! ${CEND}"
      rm -rf imagick-${imagick_for_php53_version} imagick-${imagick_version}
    else
      echo "${CFAILURE}PHP imagick module install failed, Please contact the author! ${CEND}"
    fi
  fi
  popd
}