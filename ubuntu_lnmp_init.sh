#!/bin/bash
script_name=$(basename $0)
script_dir=$(cd "$(dirname "$0")"; pwd)
script_full_path=$script_dir/$script_name
echo $script_full_path

download_dir = /download
if [ ! -d $download_dir ];then
    mkdir -p $download_dir
fi

php_user = www-data
php_group = php_user
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

apt-get -y install build-essential
apt-get -y install libxml2-dev libssl0.9.8 libssl-dev perl libtool zlib1g \
 zlib1g-dev bzip2 libbz2-dev curl libcurl4-openssl-dev libjpeg8-dev \
 libpng12-dev libfreetype6-dev libgmp-dev libicu-dev libreadline6-dev libmcrypt4 \
 libmcrypt-dev

php_version="7.0.0"
php_source_file=php-$php_version.tar.gz

pcre_version="8.37"
pcre_name="pcre-$pcre_version"
pcre_source_file="$pcre_name.tar.gz"


cd $download_dir

    if [ ! -d "source" ]; then
        mkdir source
    fi

    #if [ ! -d "opt" ]; then
    #    mkdir opt
    #fi

    cd source

    if [ ! -f $pcre_source_file ];then
    wget -O $pcre_source_file "http://downloads.sourceforge.net/project/pcre/pcre/$pcre_version/pcre-$pcre_version.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fpcre%2Ffiles%2Fpcre%2F$pcre_version%2F&ts=1446191589&use_mirror=nchc"
    fi

    if [ ! -f "Libmcrypt-2.5.8.tar.gz" ];then
    wget -O "Libmcrypt-2.5.8.tar.gz" "http://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fmcrypt%2Ffiles%2FLibmcrypt%2F2.5.8%2F&ts=1438336715&use_mirror=nchc"
    fi

    if [ ! -f "nginx-1.8.0.tar.gz" ];then
    wget -O "nginx-1.8.0.tar.gz" "http://nginx.org/download/nginx-1.8.0.tar.gz"
    fi

    if [ ! -f $php_source_file ];then
    wget -O $php_source_file "http://cn2.php.net/distributions/$php_source_file"
    fi

    tar -xvf $pcre_source_file
    #tar -xzf Libmcrypt-2.5.8.tar.gz
    #cd libmcrypt-2.5.8
    #./configure --prefix=/home/work/opt/libmcrypt-2.5.8
    #make || exit 1
    #make install || exit 2

    cd ..
    tar xzf nginx-1.8.0.tar.gz
    cd nginx-1.8.0
./configure --prefix=/usr/local/nginx-1.8.0 --sbin-path=/sbin/ --conf-path=/etc/nginx/ \
--with-http_gzip_static_module --with-pcre=../pcre-8.37/ --with-pcre-jit --with-http_ssl_module \
--with-http_realip_module
    make || exit 3
    make install || exit 4

    echo "=======================================================\r\n"
    echo "=====================nginx done========================\r\n"
    echo "=======================================================\r\n"

    php_install_dir=/usr/local/php-$php_version
    cd ..
    tar xzf $php_source_file
    cd php-$php_version
php_is_installed = 0
if [ -f "/usr/bin/php"];then
    config_cmd = "./configure --prefix=$php_install_dir --with-config-file-path=$php_install_dir/etc/php.ini --with-config-file-scan-dir=$php_install_dir/etc/ext/ --enable-fpm --with-fpm-user=$php_user --with-fpm-group=$php_group --with-zlib --with-bz2 --with-curl --with-gd --with-zlib-dir --with-png-dir --with-jpeg-dir --with-freetype-dir --with-gettext --with-gmp --with-mhash --with-mcrypt --with-openssl --with-pcre-dir --with-readline --enable-mysqlnd --with-mysql --with-mysqli --with-pdo-mysql --enable-opcache --enable-pcntl --enable-mbstring --enable-soap --enable-zip --enable-calendar --enable-exif --enable-intl --enable-gd-native-ttf --enable-shmop --with-libxml-dir --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-iconv-dir --with-mcrypt --enable-bcmath"
    php_is_installed = 1
else
    config_cmd = "./configure --prefix=/usr/local/php --bindir=/usr/bin/ --sbindir=/sbin/ --with-config-file-path=/etc/php.ini --with-config-file-scan-dir=/etc/ext/ --enable-fpm --with-fpm-user=$php_user --with-fpm-group=$php_group --with-zlib --with-bz2 --with-curl --with-gd --with-zlib-dir --with-png-dir --with-jpeg-dir --with-freetype-dir --with-gettext --with-gmp --with-mhash --with-mcrypt --with-openssl --with-pcre-dir --with-readline --enable-mysqlnd --with-mysql --with-mysqli --with-pdo-mysql --enable-opcache --enable-pcntl --enable-mbstring --enable-soap --enable-zip --enable-calendar --enable-exif --enable-intl --enable-gd-native-ttf --enable-shmop --with-libxml-dir --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-iconv-dir --with-mcrypt --enable-bcmath"
fi
    echo $config_cmd
    exit 14
    $config_cmd
    make|| exit 5
    make install||exit 6


    echo "=======================================================\r\n"
    echo "=====================php make done=====================\r\n"
    echo "=======================================================\r\n"

    if [ $php_is_installed ];then
        cd /usr/local/php-$php_version/etc
        cp -f $download_dir/source/php-$php_version/php.ini-* .
        mv -f php.ini-production php.ini

        cd /usr/local/php-$php_version/etc
        mv php-fpm.conf.default php-fpm.conf
    else
        if [ ! -d "/etc/php" ];then
            mkdir -p /etc/php/ext
        fi
        cd /etc/php
        cp -f $download_dir/source/php-$php_version/php.ini-* .
        mv -f php.ini-production php.ini

        cd /usr/local/php/etc
        mv php-fpm.conf.default php-fpm.conf
    fi

    echo "=======================================================\r\n"
    echo "=====================every job done====================\r\n"
    echo "=======================================================\r\n"
fi
