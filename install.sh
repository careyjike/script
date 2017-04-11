#!/bin/bash
#
# Author:  carey <carey@akhack.com>
# BLOG:  http://carey.akhack.com
#
# Apply to: CentOS/REHL 6+
#
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear

# set work directory
sed -i "s@^Pwd.*@Pwd=`pwd`@" ./public/options.conf

# loading public config
. ./public/color.sh
. ./public/sysinfo.sh
. ./public/options.conf
. ./public/versions.conf

# check run user
[ $(id -u) != "0" ] && { echo -e "{CFAIL}please use the root run script${CEND}"; exit 1; }

# check system
Get_Sysinfo
if [  "${OS}" = "Other" ]; then
	echo -e "${FAIL} error,system dose not support${CEND}"
  kill -9 $$
else
	. ./include/init_centos.sh
fi

# create data directory
[ ! -d "${data_dir}" ] && mkdir -p ${data_dir}

# web server
while :; do echo
  read -p "Do you want to install web server [y/n]?" Web_yn
  if [[  $Web_yn =~ ^[y,n]$ ]]; then
	  if [ "${Web_yn}" == 'y' ]; then
  		select Web_var in "Install Nginx" "Install Apache" "Install Tengine" "Install Tomcat"; do
  			if [ "${Web_var}" = "Install Apache" ]; then
          select Apache_var in "Apache-2.2" "Apache-2.4"; do
          	break
          done
        elif [ "${Web_var}" = "Install Tomcat" ]; then
        	select Tomcat_var in "Tomcat-7" "Tomcat-8"; do
            select Jdk_var in "Jdk-1.7" "Jdk-1.8"; do
              break
            done
        		break
        	done
  			fi
  			break
  		done
  		break
	  elif [ "${Web_yn}" == 'n' ]; then
      break
	  fi
	  break
  else
  	echo "${CFAIL} Error,Only input 'y' or 'n'... ${CEND} "
  fi
done

# database server
while :; do echo
  read -p "Do you want to install database server [y/n]?" Db_yn
  if [[  $Db_yn =~ ^[y,n]$ ]]; then
	  if [ "${Db_yn}" == 'y' ]; then
  		select Db_var in "Install Mysql" "Install Mariadb"; do
  			if [ "${Db_var}" = "Install Mysql" ]; then
  				select Mysql_var in "Mysql-5.5" "Mysql-5.6" "Mysql-5.7"; do
  					break
  				done
  			elif [ "${Db_var}" = "Install Mariadb" ]; then
  				select Mysql_var in "Mariadb-10.0" "Mariadb-10.1"; do
  					break
  				done
  			fi
  		  break
  		done
  		break
	  elif [ "${Web_yn}" == 'n' ]; then
      break
	  fi
	  break
  else
  	echo "${CFAIL} Error,Only input 'y' or 'n'... ${CEND} "
  fi
done

# php server
while :; do echo
  read -p "Do you want to install php server [y/n]?" Php_yn
  if [[  $Php_yn =~ ^[y,n]$ ]]; then
	  if [ "${Php_yn}" == 'y' ]; then
  		select Php_var in "Php-5.5" "Php-5.6" "Php-7.0" "Php-7.1"; do
  			if [ "${Php_var}" = "Php-5.5" ]; then
  				select	Php_cache in "Zend OPcache" "XCache" "APCU"; do break;done
  		  elif [ "${Php_var}" = "Php-5.6" ]; then
  		  	select Php_cache in "Zend OPcache" "XCache" "APCU"; do break;done
  		  elif [ "${Php_var}" = "Php-7.0" ] ||  [ "${Php_var}" = "Php-7.1" ]; then
  		  	select Php_cache in "Zend OPcache" "APCU"; do break;done
  		  fi
  		  break
  		done
  		break
	  elif [ "${Web_yn}" == 'n' ]; then
      break
	  fi
	  break
  else
  	echo "${CFAIL} Error,Only input 'y' or 'n'... ${CEND} "
  fi
done

# ImageMagick or GraphicsMagick
while :; do echo
  read -p "Do you want to install ImageMagick or GraphicsMagick [y/n]?" Magick_yn
  if [[  $Magick_yn =~ ^[y,n]$ ]]; then
	  if [ "${Magick_yn}" == 'y' ]; then
  		select Magick_var in "ImageMagick" "GraphicsMagick"; do
  		  break
  		done
  		break
	  elif [ "${Magick_yn}" == 'n' ]; then
      break
	  fi
	  break
  else
  	echo "${CFAIL} Error,Only input 'y' or 'n'... ${CEND} "
  fi
done

# pureftpd server
while :; do echo
  read -p "Do you want to install pureftpd [y/n]?" Ftp_yn
  if [[  $Ftp_yn =~ ^[y,n]$ ]]; then
	  break
  else
  	echo "${CFAIL} Error,Only input 'y' or 'n'... ${CEND} "
  fi
done

# redis server
while :; do echo
  read -p "Do you want to install redis [y/n]?" Redis_yn
  if [[ $Redis_yn =~ ^[y,n]$ ]]; then
    break
  else
  	echo "${CFAIL}Error,Only input 'y' or 'n'...${CEND}"
  fi
  break
done

# memcached server
while :; do echo
  read -p "Do you want to install memcached [y/n]?" Memcached_yn
  if [[ $Memcached_yn =~ ^[y,n]$ ]]; then
    break
  else
  	echo "${CFAIL}Error,Only input 'y' or 'n'...${CEND}"
  fi
  break
done

############

# Init
Init_Centos

# jemalloc
. ./include/jemalloc.sh
Install_Jemalloc

# database
# source or binary
install_mod=source
if [ "${Mysql_var}" = "Mysql-5.5" ]; then
	. ./include/MySQL5.5.sh
	Install_MySQL55
elif [ "${Mysql_var}" = "Mysql-5.6" ]; then
	. ./include/MySQL5.6.sh
	Install_MySQL56
elif [ "${Mysql_var}" = "Mysql-5.7" ]; then
	. ./include/Boost.sh
	. ./include/MySQL5.7.sh
  Install_Boost
	Install_MySQL57
elif [ "${Mysql_var}" = "Mariadb-10.0" ]; then
	. ./include/MariaDB10.0.sh
elif [ "${Mysql_var}" = "Mariadb-10.1" ]; then
	. ./include/MariaDB10.1.sh
fi

# web server
if [ "${Web_var}" = "Install Nginx" ]; then
	. ./include/Nginx.sh
	Install_Nginx
elif [ "${Web_var}" = "Install Tengine" ]; then
	. ./include/Tengine.sh
	Install_Tengine
elif [ "${Apache_var}" = "Apache-2.2" ]; then
	. ./include/Apache2.2.sh
	Install_Apache22
elif [ "${Apache_var}" = "Apache-2.4" ]; then
	. ./include/Apache2.4.sh
	Install_Apache24
elif [ "${Tomcat_var}" = "Tomcat-7" ]; then
  if [ "${Jdk_var}" = "Jdk-1.7" ]; then
    . ./include/Jdk1.7.sh
    Install-JDK17
  elif [ "${Jdk_var}" = "Jdk-1.8" ]; then
    . ./include/Jdk-1.8.sh
    Install-JDK18
  fi
	. ./include/Tomcat7.sh
	Install_Tomcat7
elif [ "${Tomcat_var}" = "Tomcat-8" ]; then
	. ./include/Tomcat8.sh
  Install_Tomcat8
fi

# php server
if [ "${Php_var}" = "Php-5.5" ]; then
	. ./include/php5.5.sh
  Install_PHP55
elif [ "${Php_var}" = "Php-5.6" ]; then
	. ./include/php5.6.sh
  Install_PHP56
elif [ "${Php_var}" = 'Php-7.0' ]; then
	. ./include/php7.0.sh
  Install_PHP70
elif [ "${Php_var}" = "Php-7.1" ]; then
	. ./include/php7.1.sh
  Install_PHP71
fi

# ImageMagick or GraphicsMagick
if [ "${Magick_var}" == "ImageMagick" ]; then
  . include/ImageMagick.sh
  [ ! -d "/usr/local/imagemagick" ] && Install_ImageMagick
  [ ! -e "`$php_install_dir/bin/php-config --extension-dir`/imagick.so" ] && Install_php-imagick
elif [ "${Magick_var}" == "GraphicsMagick" ]; then
  . include/GraphicsMagick.sh
  [ ! -d "/usr/local/graphicsmagick" ] && Install_GraphicsMagick
  [ ! -e "`$php_install_dir/bin/php-config --extension-dir`/gmagick.so" ] && Install_php-gmagick
fi

# php cache
if [ "${Php_cache}" = "Zend OPcache" ]; then
	. ./include/ZendOpcache.sh
  Install_ZendOPcache
elif [ "${Php_cache}" = "XCache" ]; then
	. ./include/XCache.sh
  Install_XCache
elif [ "${Php_cache}" = "APCU" ]; then
	. ./include/APCU.sh
  Install_APCU
fi

# ftp
if [ "${Ftp_yn}" = 'y' ]; then
	. ./include/PureFtpd.sh
  Install_PureFTPd
fi

# redis
if [ "${Redis_yn}" = 'y' ]; then
	. ./include/redis.sh
  Install_redis-server
  if [ "${Php_yn}" = 'y' ]; then
    Install_php-redis
  fi
fi

# memcached
if [ "${Memcached_yn}" = 'y' ]; then
	. ./include/memcached.sh
  Install_memcached
  if [ "${Php_yn}" = 'y' ]; then
    # Install_php-memcache
    Install_php-memcached
  fi
fi