#!/bin/bash
Install_PureFTPd() {
  pushd ${Pwd}/src

  id -u ${run_user} >/dev/null 2>&1
  [ $? -ne 0 ] && useradd -M -s /sbin/nologin ${run_user}
  src_url=https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-${pureftpd_version}.tar.gz && wget -c --tries=6 $src_url

  tar xzf pure-ftpd-${pureftpd_version}.tar.gz
  pushd pure-ftpd-${pureftpd_version}
  [ ! -d "${pureftpd_install_dir}" ] && mkdir -p ${pureftpd_install_dir}
  ./configure --prefix=${pureftpd_install_dir} CFLAGS=-O2 --with-puredb --with-quotas --with-cookie --with-virtualhosts --with-virtualchroot --with-diraliases --with-sysquotas --with-ratios --with-altlog --with-paranoidmsg --with-shadow --with-welcomemsg  --with-throttling --with-uploadscript --with-language=english --with-rfc2640
  make -j ${THREAD} && make install
  if [ -e "${pureftpd_install_dir}/sbin/pure-ftpwho" ]; then
    [ ! -e "${pureftpd_install_dir}/etc" ] && mkdir ${pureftpd_install_dir}/etc
    popd
    /bin/cp ../init.d/pureftpd /etc/init.d/pureftpd
    /bin/cp ../config/pure-ftpd.conf ${pureftpd_install_dir}/etc
    sed -i "s@/usr/local/pureftpd@${pureftpd_install_dir}@g" /etc/init.d/pureftpd
    chmod +x /etc/init.d/pureftpd
    chkconfig --add pureftpd; chkconfig pureftpd on

    sed -i "s@^PureDB.*@PureDB  ${pureftpd_install_dir}/etc/pureftpd.pdb@" ${pureftpd_install_dir}/etc/pure-ftpd.conf
    sed -i "s@^LimitRecursion.*@LimitRecursion  65535 8@" ${pureftpd_install_dir}/etc/pure-ftpd.conf
    ulimit -s unlimited
    service pureftpd start

    # iptables Ftp
	  if [ -z "$(grep '20000:30000' /etc/sysconfig/iptables)" ]; then
	    iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 21 -j ACCEPT
	    iptables -I INPUT 6 -p tcp -m state --state NEW -m tcp --dport 20000:30000 -j ACCEPT
	    service iptables save
	  fi

    echo "${CSUCCESSFUL}Pure-Ftp installed successfully! ${CEND}"
  else
    rm -rf ${pureftpd_install_dir}
    echo "${CFAIL}Pure-Ftpd install failed, Please contact the author! ${CEND}"
    kill -9 $$
  fi
  popd
}
