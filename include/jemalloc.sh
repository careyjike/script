#!/bin/bash
Install_Jemalloc() {
  pushd ${Pwd}/src

  if [ ! -e "/usr/local/lib/libjemalloc.so" ]; then
    # download
    src_url=https://github.com/jemalloc/jemalloc/releases/download/${jemalloc_version}/jemalloc-${jemalloc_version}.tar.bz2 && wget -c --tries=6 --no-check-certificate $src_url

    tar xjf jemalloc-${jemalloc_version}.tar.bz2
    pushd jemalloc-${jemalloc_version}
    LDFLAGS="${LDFLAGS} -lrt" ./configure
    make && make install
    unset LDFLAGS
    popd

    if [ -f "/usr/local/lib/libjemalloc.so" ]; then
      if [ "$OS_BIT" == '64' -a "$OS" == 'CentOS' ]; then
        ln -s /usr/local/lib/libjemalloc.so.2 /usr/lib64/libjemalloc.so.1
      else
        ln -s /usr/local/lib/libjemalloc.so.2 /usr/lib/libjemalloc.so.1
      fi
      echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
      ldconfig
      echo -e "${CSUCCESS}jemalloc module installed successfully! ${CEND}"
      rm -rf jemalloc-${jemalloc_version}
    else
      echo -e "${CFAILURE}jemalloc install failed, Please contact the author! ${CEND}"
      kill -9 $$
    fi
  fi
  popd
}