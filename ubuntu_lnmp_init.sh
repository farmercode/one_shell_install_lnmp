#!/bin/bash
script_name=$(basename $0)
script_dir=$(cd "$(dirname "$0")"; pwd)
script_full_path=$script_dir/$script_name
echo $script_full_path

#获得当前系统版本
os_version=`lsb_release -r|awk '{print $2}'`

case $os_version in
  "16.04")
      libmysqlclient="libmysqlclient20"
      ;;
  *)
      libmysqlclient="libmysqlclient18"
      ;;
esac

current_user=`whoami`

download_dir="/download"
if [ ! -d $download_dir ];then
    mkdir -p $download_dir
fi

php_user=www-data
php_group=$php_user
#判断用户组是否存在，不存在就创建
egrep "^$php_group" /etc/group >& /dev/null
if [[ $? -ne 0 ]];then
    groupadd $php_group
fi

#判断用户是否存在，不存在就创建
egrep "^$php_user" /etc/passwd >& /dev/null
if [ $? -ne 0 ];then
    useradd $php_user -g $php_group -M
fi

echo "prepare ready!"
echo "start install package dependency!"


apt-get -y install build-essential
apt-get -y install libxml2-dev perl libtool zlib1g libssl-dev \
 zlib1g-dev bzip2 libbz2-dev curl libcurl4-openssl-dev libjpeg8-dev \
 libpng12-dev libfreetype6-dev libgmp-dev libicu-dev libreadline6-dev libmcrypt4 \
 libmcrypt-dev $libmysqlclient libmysqlclient-dev libpcre3 libpcre3-dev

echo "package dependency installed!"

php_version="5.6.30"
php_source_file=php-$php_version.tar.gz

pcre_version="8.39"
pcre_name="pcre-$pcre_version"
pcre_source_file="$pcre_name.tar.gz"

# 创建临时文件下载目录
source_dir="$download_dir"/source
echo $source_dir
if [[ ! -d "$source_dir" ]]; then
    mkdir $source_dir
fi
cd $source_dir


if [ ! -f "$pcre_source_file" ];then
    wget -O $pcre_source_file "http://www.helpergarden.com/download/$pcre_source_file"
fi

nginx_source_file="nginx-1.8.0.tar.gz"
if [ ! -f  $nginx_source_file ];then
    wget -O $nginx_source_file "http://nginx.org/download/nginx-1.8.0.tar.gz"
fi

if [ ! -f $php_source_file ];then
    wget -O $php_source_file "http://cn2.php.net/distributions/$php_source_file"
fi

if [ ! -d "/etc/nginx" ];then
    mkdir -p /etc/nginx/vhost
fi
cd $download_dir/source

if [ ! -f "/sbin/nginx" ];then
    tar -xvf $pcre_source_file
    tar -xvf $nginx_source_file || exit 201
    cd nginx-1.8.0
    nginx_config="./configure --prefix=/usr/local/nginx-1.8.0 --sbin-path=/sbin/ --conf-path=/etc/nginx/ \
    --with-http_gzip_static_module --with-pcre=../pcre-8.37/ --with-pcre-jit --with-http_ssl_module \
    --with-http_realip_module"
    echo $nginx_config

    sleep 1

    $nginx_config
    make || exit 3
    make install || exit 4
    cp conf/* /etc/nginx/

    echo "=======================================================\r\n"
    echo "=====================nginx done========================\r\n"
    echo "=======================================================\r\n"
fi

cd $download_dir/source

php_install_dir=/usr/local/php-$php_version
if [ ! -d "$download_dir/source/php-$php_version" ];then
    tar -xvf $php_source_file
fi

cd php-$php_version
php_is_installed=0

if [ ! -f "/usr/include/gmp.h" ];then
    if [ -f "/usr/include/x86_64-linux-gnu/gmp.h" ];then
        ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h
    fi
fi

if [ -f "/usr/bin/php" ];then
    config_cmd="./configure --prefix=$php_install_dir --with-config-file-path=$php_install_dir/etc/php.ini --with-config-file-scan-dir=$php_install_dir/etc/ext/ --enable-fpm --with-fpm-user=$php_user --with-fpm-group=$php_group --with-zlib --with-bz2 --with-curl --with-gd --with-zlib-dir --with-png-dir --with-jpeg-dir --with-freetype-dir --with-gettext --with-gmp --with-mhash --with-mcrypt --with-openssl --with-pcre-dir --with-readline --enable-mysqlnd --with-mysql --with-mysqli --with-pdo-mysql --enable-opcache --enable-pcntl --enable-mbstring --enable-soap --enable-zip --enable-calendar --enable-exif --enable-intl --enable-gd-native-ttf --enable-shmop --with-libxml-dir --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-iconv-dir --with-mcrypt --enable-bcmath"
    php_is_installed=1
else
    config_cmd="./configure --prefix=/usr/local/php --bindir=/usr/bin/ --sbindir=/sbin/ --with-config-file-path=/etc/php/php.ini --with-config-file-scan-dir=/etc/php/ext/ --enable-fpm --with-fpm-user=$php_user --with-fpm-group=$php_group --with-zlib --with-bz2 --with-curl --with-gd --with-zlib-dir --with-png-dir --with-jpeg-dir --with-freetype-dir --with-gettext --with-gmp --with-mhash --with-mcrypt --with-openssl --with-pcre-dir --with-readline --enable-mysqlnd --with-mysql --with-mysqli --with-pdo-mysql --enable-opcache --enable-pcntl --enable-mbstring --enable-soap --enable-zip --enable-calendar --enable-exif --enable-intl --enable-gd-native-ttf --enable-shmop --with-libxml-dir --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-iconv-dir --with-mcrypt --enable-bcmath"
fi
echo $config_cmd

$config_cmd

make|| exit 5
make install||exit 6


echo "=======================================================\r\n"
echo "=====================php make done=====================\r\n"
echo "=======================================================\r\n"

if [ $php_is_installed -eq 1 ];then
    cd /usr/local/php-$php_version/etc
    cp -f $download_dir/source/php-$php_version/php.ini-* .
    mv -f php.ini-development php.ini

    cd /usr/local/php-$php_version/etc
    mv php-fpm.conf.default php-fpm.conf
else
    if [ ! -d "/etc/php" ];then
        mkdir -p /etc/php/ext
    fi
    cd /etc/php
    cp -f $download_dir/source/php-$php_version/php.ini-* .
    mv -f php.ini-development php.ini

    cd /usr/local/php/etc
    mv php-fpm.conf.default php-fpm.conf
fi
#复制nginx.service,php-fpm.service文件到systemd配置文件目录
nginx_systemd_config="nginx.service"
fpm_systemd_config="php-fpm.service"
systemd_config_dir="/lib/systemd/system/"
if [ ! -f "$systemd_config_dir$nginx_systemd_config" ]; then
    cp $script_dir"/"$nginx_systemd_config $systemd_config_dir
fi
if [ ! -f "$systemd_config_dir$fpm_systemd_config"];then
    cp $script_dir"/"$fpm_systemd_config $systemd_config_dir
fi
#重载系统systemd配置文件
systemctl daemon-reload
systemctl enable $nginx_systemd_config
systemctl enable $fpm_systemd_config

#将PHPRC加入/etc/profile
egrep "PHPRC" /etc/profile
if [ $? -eq 1 ];then
    if [ "root" == $current_user ];then
        echo "export PHPRC=/etc/php:/etc/php/ext" >> /etc/profile
        echo "" >> /etc/profile
    else
        echo "Current user:$current_user"
        echo "Please add\"export PHPRC=/etc/php:/etc/php/ext\" to your /etc/profile";
    fi
fi

echo "=======================================================\r\n"
echo "=====================every job done====================\r\n"
echo "=======================================================\r\n"
