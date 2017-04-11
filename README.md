
## lanmp一键安装脚本
>**目前仅适用于centos**

### 安装方式
```bash
git  clone https://git.oschina.net/careyjike_173/script.git &&  cd script;chmod +x install.sh; ./install.sh | tee -a install.log
```

**安装完成后执行** 
```bash
source /etc/profile
```

### 安装详情
- Nginx
- Tengine
- Apache
- ~~Tomcat~~
- mysql
- php
- ImageMagick
- GraphicsMagick
- ZendOpcache
- XCache
- APCU
- Jemalloc
- PureFtpd
- Redis
- Memcache

### 注意
>如果需要修改版本号和安装目录等，请修改 `public/versions.conf` 和 `public/options.conf` 文件。

>**`mysql pssword`** 默认为 `root`,修改 `public/option.conf` 中 `dbrootpwd`


### 问题反馈
欢迎通过[Issues](http://git.oschina.net/careyjike_173/script/issues)反馈

