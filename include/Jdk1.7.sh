#!/bin/bash


Install-JDK17() {
  pushd ${Pwd}/src


  JDK_FILE="jdk-`echo $jdk17_version | awk -F. '{print $2}'`u`echo $jdk17_version | awk -F_ '{print $NF}'`-linux-$SYS_BIG_FLAG.tar.gz"
  JAVA_dir=/usr/java
  JDK_NAME="jdk$jdk17_version"
  JDK_PATH=$JAVA_dir/$JDK_NAME

  [ -n "`rpm -qa | grep jdk`" ] && rpm -e `rpm -qa | grep jdk`

  src_url=http://mirrors.linuxeye.com/jdk/${JDK_FILE} && wget -c --tries=6 $src_url

  tar xzf $JDK_FILE
  if [ -d "$JDK_NAME" ]; then
    rm -rf $JAVA_dir; mkdir -p $JAVA_dir
    mv $JDK_NAME $JAVA_dir
    [ -z "`grep ^'export JAVA_HOME=' /etc/profile`" ] && { [ -z "`grep ^'export PATH=' /etc/profile`" ] && echo  "export JAVA_HOME=$JDK_PATH" >> /etc/profile || sed -i "s@^export PATH=@export JAVA_HOME=$JDK_PATH\nexport PATH=@" /etc/profile; } || sed -i "s@^export JAVA_HOME=.*@export JAVA_HOME=$JDK_PATH@" /etc/profile
    [ -z "`grep ^'export CLASSPATH=' /etc/profile`" ] && sed -i "s@export JAVA_HOME=\(.*\)@export JAVA_HOME=\1\nexport CLASSPATH=\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib@" /etc/profile
    [ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep '$JAVA_HOME/bin' /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=\$JAVA_HOME/bin:\1@" /etc/profile
    [ -z "`grep ^'export PATH=' /etc/profile | grep '$JAVA_HOME/bin'`" ] && echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
    . /etc/profile
    echo -e "${CSUCCESSFUL}$JDK_NAME installed successfully! ${CEND}"
  else
    rm -rf $JAVA_dir
    echo -e "${CFAIL}JDK install failed, Please contact the author! ${CEND}"
    kill -9 $$
  fi
  popd
}