#!/bin/bash

Get_Sysinfo() {
  OSS_Url=http://oss.akhack.com/src
  THREAD=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)

  # get memory
  Mem=`free -m | awk '/Mem:/{print $2}'`
  Swap=`free -m | awk '/Swap:/{print $2}'`

  if [ $Mem -le 640 ]; then
    Mem_level=512M
    Memory_limit=64
    THREAD=1
  elif [ $Mem -gt 640 -a $Mem -le 1280 ]; then
    Mem_level=1G
    Memory_limit=128
  elif [ $Mem -gt 1280 -a $Mem -le 2500 ]; then
    Mem_level=2G
    Memory_limit=192
  elif [ $Mem -gt 2500 -a $Mem -le 3500 ]; then
    Mem_level=3G
    Memory_limit=256
  elif [ $Mem -gt 3500 -a $Mem -le 4500 ]; then
    Mem_level=4G
    Memory_limit=320
  elif [ $Mem -gt 4500 -a $Mem -le 8000 ]; then
    Mem_level=6G
    Memory_limit=384
  elif [ $Mem -gt 8000 ]; then
    Mem_level=8G
    Memory_limit=448
  fi


  # get dist name
  if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
    OS='CentOS'
  elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
    OS='RHEL'
  else
    OS='Other'
  fi

  # get system version
  if [ "${OS}" = "RHEL" ]; then
    if grep -Eqi "release 5." /etc/redhat-release; then
      CENTOS_RHEL_VERSION='5'
    elif grep -Eqi "release 6." /etc/redhat-release; then
      CENTOS_RHEL_VERSION='6'
    elif grep -Eqi "release 7." /etc/redhat-release; then
      CENTOS_RHEL_VERSION='7'
    fi
  elif [ "${OS}" = "CentOS" ]; then
    if grep ' 5\.' /etc/redhat-release; then
      CENTOS_RHEL_VERSION='5'
    elif grep ' 6\.' /etc/redhat-release; then
      CENTOS_RHEL_VERSION='6'
    elif grep ' 7\.' /etc/redhat-release; then
      CENTOS_RHEL_VERSION='7'
    fi
  fi

  # get system bit
  if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
    OS_BIT=64
    SYS_BIG_FLAG=x64
    SYS_BIT_a=x86_64;SYS_BIT_b=x86_64;
  else
    OS_BIT=32
    SYS_BIG_FLAG=i586
    SYS_BIT_a=x86;SYS_BIT_b=i686;
  fi

  LIBC_YN=$(awk -v A=$(getconf -a | grep GNU_LIBC_VERSION | awk '{print $NF}') -v B=2.14 'BEGIN{print(A>=B)?"0":"1"}')
  [ $LIBC_YN == '0' ] && GLIBC_FLAG=linux-glibc_214 || GLIBC_FLAG=linux

  if uname -m | grep -Eqi "arm"; then
    armPlatform="y"
    if uname -m | grep -Eqi "armv7"; then
      TARGET_ARCH="armv7"
    elif uname -m | grep -Eqi "armv8"; then
      TARGET_ARCH="arm64"
    else
      TARGET_ARCH="unknown"
    fi
  fi
}