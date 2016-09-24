#!/bin/bash
script_name=$(basename $0)
script_dir=$(cd "$(dirname "$0")"; pwd)
script_full_path=$script_dir/$script_name
echo $script_full_path

#安装EPEL源
yum repolist|egrep "epel" >& /dev/null
if [ $? -ne 0 ];then
        epel_file="epel-release-7-8.noarch.rpm"
        #wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm -O $epel_file
        rpm -ivh $epel_file
        yum makecache
fi

download_dir=/download
if [ ! -d $download_dir ];then
    mkdir -p $download_dir
fi

php_user=www-data
php_group=$php_user
#判断用户组是否存在，不存在就创建
egrep "^$php_group" /etc/group >& /dev/null
if [ $? -ne 0 ];then
    groupadd $php_group
fi

#判断用户是否存在，不存在就创建
egrep "^$php_user" /etc/passwd >& /dev/null
if [ $? -ne 0 ];then
    useradd $php_user -g $php_group -M
fi

echo "prepare ready!"
echo "start install package dependency!"

yum -y update

yum -y install autoconf automake gcc gcc-c++ libxml2-devel openssl-devel openssl-libs perl libtool-ltdl-devel zlib zlib-devel \
bzip2-devel libcurl-devel libjpeg-turbo libjpeg-turbo-devel libpng-devel \
 libpng12-dev freetype-devel gmp-devel libicu-devel readline-devel libmcrypt-devel

php_version="5.6.26"
php_source_file=php-$php_version.tar.gz

pcre_version="8.37"
pcre_name="pcre-$pcre_version"
pcre_source_file="$pcre_name.tar.gz"
nginx_version=1.8.0
nginx_source_file="nginx-$nginx_version.tar.gz"

source_dir="$download_dir"/source

if [ ! -d "$source_dir" ]; then
    mkdir $source_dir
fi
cd $source_dir

    #if [ ! -d "opt" ]; then
    #    mkdir opt
    #fi

    cd source

    if [ ! -f $pcre_source_file ];then
    wget -O $pcre_source_file "http://downloads.sourceforge.net/project/pcre/pcre/$pcre_version/pcre-$pcre_version.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fpcre%2Ffiles%2Fpcre%2F$pcre_version%2F&ts=1446191589&use_mirror=nchc"
    fi

    if [ ! -f "$nginx_source_file" ];then
    wget -O "$nginx_source_file" "http://nginx.org/download/$nginx_source_file"
    fi

    if [ ! -f $php_source_file ];then
    wget -O $php_source_file "http://cn2.php.net/distributions/$php_source_file"
    fi
    if [ ! -d "/etc/nginx" ];then
        mkdir -p /etc/nginx/vhost
    fi

    if [ ! -f "/sbin/nginx" ];then
        tar -xvf $pcre_source_file || exit 201
        tar -xvf $nginx_source_file || exit 202
        cd nginx-1.8.0
    nginx_config="./configure --prefix=/usr/local/nginx-1.8.0 --sbin-path=/sbin/ --conf-path=/etc/nginx/ \
    --with-http_gzip_static_module --with-pcre=../pcre-8.37/ --with-pcre-jit --with-http_ssl_module \
    --with-http_realip_module"
    echo $nginx_config


    $nginx_config
        make || exit 301
        make install || exit 302
        cd ..
        echo "=======================================================\r\n"
        echo "=====================nginx done========================\r\n"
        echo "=======================================================\r\n"
    fi

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

    make|| exit 401
    make install||exit 402


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
