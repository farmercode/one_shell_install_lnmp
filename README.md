# one_shell_install_lnmp
<b>一键安装php</b>，目前针对默认安装的是php5.6.20！<br>
目前在ubuntu15.10和centos7中进行过测试，可以成功安装！<br>
<b>使用简介</b><br>
<b>一 给脚本执行权限</b> <br/>
进入你的one_shell_install_lnmp的git目录下面，执行如下命令：<br>
chmod a+x ubuntu_lnmp_init.sh<br>
或者<br>
chmod a+x centos7_lnmp_init.sh<br>
<b>二 执行脚本</b><br>
sudo ./ubuntu_lnmp_init.sh
或者<br>
./centos7_lnmp_init.sh<br>
<br>
centos如果你不是root角色也请类似使用ubuntu那样使用sudo来处理。<br>
默认php的安装位置在/usr/local/php,所以无论是centos7还是ubuntu15*最好用root权限去运行，最后向/etc/profile中加入PHPRC必须需要root权限。如果觉得没必要刻可以自行注意掉那部分逻辑即可！

####注意
如果你的ubuntu或者centos源地址部分软件包无法下载，换个源地址试试。国内的朋友可以试试阿里云的镜像或者163的镜像！
####更新
centos7脚本更新:由于我使用的是163的源上面没有libmcrypt-devel这个包，所以就在脚本里增加了**epel源**(Extra Packages for Enterprise Linux)
