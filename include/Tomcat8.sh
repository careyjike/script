#!/bin/bash

Install_Tomcat8() {
  pushd ${Pwd}/src
  . /etc/profile

  id -u ${run_user} >/dev/null 2>&1
  [ $? -ne 0 ] && useradd -M -s /bin/bash ${run_user} || { [ -z "$(grep ^${run_user} /etc/passwd | grep '/bin/bash')" ] && usermod -s /bin/bash ${run_user}; }

  # download
  src_url=http://archive.apache.org/dist/apr/apr-${apr_version}.tar.gz && wget -c --tries=6 $src_url
  src_url=http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v${tomcat8_version}/src/apache-tomcat-${tomcat8_version}-src.tar.gz && wget -c --tries=6 $src_url
  src_url=http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v${tomcat8_version}/bin/extras/catalina-jmx-remote.jar && wget -c --tries=6 $src_url
  src_url=https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-connectors/native/1.2.12/source/tomcat-native-${native_version}-src.tar.gz && wget -c --tries=6 --no-check-certificate $src_url

  # install apr
  if [ ! -e "/usr/local/apr/bin/apr-1-config" ]; then
    tar xzf apr-${apr_version}.tar.gz
    pushd apr-${apr_version}
    ./configure
    make -j ${THREAD} && make install
    popd
    rm -rf apr-${apr_version}
  fi

  tar xzf apache-tomcat-${tomcat8_version}-src.tar.gz
  [ ! -d "${tomcat_install_dir}" ] && mkdir -p ${tomcat_install_dir}
  /bin/cp -R apache-tomcat-${tomcat8_version}-src/* ${tomcat_install_dir}
  rm -rf ${tomcat_install_dir}/webapps/{docs,examples,host-manager,manager,ROOT/*}

  if [ ! -e "${tomcat_install_dir}/conf/server.xml" ]; then
    rm -rf ${tomcat_install_dir}
    echo -e "${CFAIL}Tomcat install failed, Please contact the author! ${CEND}"
    kill -9 $$
  fi

  /bin/cp catalina-jmx-remote.jar ${tomcat_install_dir}/lib
  [ ! -d "${tomcat_install_dir}/lib/catalina" ] &&  mkdir -p ${tomcat_install_dir}/lib/catalina
  pushd ${tomcat_install_dir}/lib/catalina
  jar xf ../catalina.jar
  sed -i 's@^server.info=.*@server.info=Tomcat@' org/apache/catalina/util/ServerInfo.properties
  sed -i 's@^server.number=.*@server.number=8@' org/apache/catalina/util/ServerInfo.properties
  sed -i "s@^server.built=.*@server.built=$(date)@" org/apache/catalina/util/ServerInfo.properties
  jar cf ../catalina.jar ./*
  popd
  rm -rf ${tomcat_install_dir}/lib/catalina

  pushd ${tomcat_install_dir}/bin
  tar xzf tomcat-native-${native_version}-src.tar.gz
  pushd tomcat-native-*-src/native
    ./configure --with-apr=/usr/local/apr --with-ssl=${openssl_install_dir}
    make -j ${THREAD} && make install
  popd
  rm -rf tomcat-native-*
  if [ -e "/usr/local/apr/lib/libtcnative-1.la" ]; then
    [ ${Mem} -le 768 ] && let Xms_Mem="${Mem}/3" || Xms_Mem=256
    let XmxMem="${Mem}/2"
    cat > ${tomcat_install_dir}/bin/setenv.sh << EOF
JAVA_OPTS='-Djava.security.egd=file:/dev/./urandom -server -Xms${Xms_Mem}m -Xmx${XmxMem}m -Dfile.encoding=UTF-8'
CATALINA_OPTS="-Djava.library.path=/usr/local/apr/lib"
# -Djava.rmi.server.hostname=$IPADDR
# -Dcom.sun.management.jmxremote.password.file=\$CATALINA_BASE/conf/jmxremote.password
# -Dcom.sun.management.jmxremote.access.file=\$CATALINA_BASE/conf/jmxremote.access
# -Dcom.sun.management.jmxremote.ssl=false"
EOF
    chmod +x ./*.sh
    /bin/mv ${tomcat_install_dir}/conf/server.xml{,_bk}
    popd # goto ${Pwd}/src
    mkdir -p ${wwwroot_dir}/default
    /bin/cp ${Pwd}/config/server.xml ${tomcat_install_dir}/conf
    sed -i "s@/usr/local/tomcat@${tomcat_install_dir}@g" ${tomcat_install_dir}/conf/server.xml

    if [ -z "$(grep -w '8080' /etc/sysconfig/iptables)" ]; then
      iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
      service iptables save
    fi


    [ ! -d "${tomcat_install_dir}/conf/vhost" ] && mkdir ${tomcat_install_dir}/conf/vhost
    cat > ${tomcat_install_dir}/conf/vhost/localhost.xml << EOF
<Host name="localhost" appBase="${wwwroot_dir}/default" unpackWARs="true" autoDeploy="true">
  <Context path="" docBase="${wwwroot_dir}/default" debug="0" reloadable="false" crossContext="true"/>
  <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
    prefix="localhost_access_log." suffix=".txt" pattern="%h %l %u %t &quot;%r&quot; %s %b" />
</Host>
EOF
    # logrotate tomcat catalina.out
    cat > /etc/logrotate.d/tomcat << EOF
${tomcat_install_dir}/logs/catalina.out {
  daily
  rotate 5
  missingok
  dateext
  compress
  notifempty
  copytruncate
}
EOF
    [ -z "$(grep '<user username="admin" password=' ${tomcat_install_dir}/conf/tomcat-users.xml)" ] && sed -i "s@^</tomcat-users>@<role rolename=\"admin-gui\"/>\n<role rolename=\"admin-script\"/>\n<role rolename=\"manager-gui\"/>\n<role rolename=\"manager-script\"/>\n<user username=\"admin\" password=\"$(cat /dev/urandom | head -1 | md5sum | head -c 10)\" roles=\"admin-gui,admin-script,manager-gui,manager-script\"/>\n</tomcat-users>@" ${tomcat_install_dir}/conf/tomcat-users.xml
    cat > ${tomcat_install_dir}/conf/jmxremote.access << EOF
monitorRole   readonly
controlRole   readwrite \
              create javax.management.monitor.*,javax.management.timer.* \
              unregister
EOF
    cat > ${tomcat_install_dir}/conf/jmxremote.password << EOF
monitorRole  $(cat /dev/urandom | head -1 | md5sum | head -c 8)
# controlRole   R&D
EOF
    chown -R ${run_user}.${run_user} ${tomcat_install_dir}
    /bin/cp ${Pwd}/init.d/tomcat /etc/init.d/tomcat
    sed -i "s@JAVA_HOME=.*@JAVA_HOME=${JAVA_HOME}@" /etc/init.d/tomcat
    sed -i "s@^CATALINA_HOME=.*@CATALINA_HOME=${tomcat_install_dir}@" /etc/init.d/tomcat
    sed -i "s@^TOMCAT_USER=.*@TOMCAT_USER=${run_user}@" /etc/init.d/tomcat
    chkconfig --add tomcat; chkconfig tomcat on
    echo -e "${CSUCCESSFUL}Tomcat installed successfully! ${CEND}"
    rm -rf apache-tomcat-${tomcat8_version}
  else
    popd
    echo -e "${CFAIL}Tomcat install failed, Please contact the author! ${CEND}"
  fi
  /etc/init.d/tomcat start
  popd
}
