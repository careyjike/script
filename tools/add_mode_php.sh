#!/bin/bash
clear

# loading public config
. ./public/color.sh
. ./public/sysinfo.sh
. ./public/options.conf
. ./public/versions.conf

# check run user
[ $(id -u) != "0" ] && { echo "{CFAIL}please use the root run script${CEND}"; exit 1; }

# check system
Get_Sysinfo
if [  "${OS}" = "Other" ]; then
	echo -e "${FAIL} error,system dose not support${CEND}"
  kill -9 $$
fi

while :; do echo
  select Mode_var in "Apcu" "ImageMagick" "GraphicsMagick" "Memcache" "Memcached" "Redis"; do echo
    if [ "${Mode_var}" = "Apcu" ]; then
    	if [ ! "`${php_install_dir}/bin/php -m | grep apcu`" ]; then
    		. ./include/APCU.sh
    	  Install_APCU
    	else
    		echo -e "${CFAIL} php extension apcu already existing ${CEND}"
    	fi
    elif [ "${Mode_var}" = "ImageMagick" ]; then
    	if [ ! "`${php_install_dir}/bin/php -m | grep imagick`" ]; then
	    	. ./include/ImageMagick.sh
	    	if [ ! -f "/usr/local/imagemagick/bin/magick" ]; then
	    	  Install_ImageMagick
	      fi
	    	Install_php-imagick
	    else
	    	echo -e "${CFAIL} php extension Imagemagick already existing ${CEND}"
	    fi
    elif [ "${Mode_var}" = "GraphicsMagick" ]; then
    	if [ ! "`${php_install_dir}/bin/php -m | grep gmagick`" ]; then
    	  . ./include/GraphicsMagick.sh
    	  if [ ! -f "/usr/local/graphicsmagick/bin/gm" ]; then
    	  	Install_GraphicsMagick
    	  fi
    	  Install_php-gmagick
      else
      	echo -e "${CFAIL} php extension GraphicsMagick already existing ${CEND}"
      fi
    elif [ "${Mode_var}" = "Memcache" ]; then
    	. ./include/memcached.sh
    	if [ ! -f "${memcached_install_dir}/bin/memcached" ]; then
	    	Install_memcached
	    fi
    	Install_php-memcache
    elif [ "${Mode_var}" = "Memcached" ]; then
    	. ./include/memcached.sh
    	if [ ! -f "${memcached_install_dir}/bin/memcached" ]; then
	    	Install_memcached
	    fi
    	Install_php-memcached
    elif [ "${Mode_var}" = "Redis" ]; then
    	. ./include/redis.sh
    	if [ ! -f "${redis_install_dir}/bin/redis-server" ]; then
    		Install_redis-server
    	fi
    	Install_php-redis
    fi
    break
  done
  break
done
