# one_shell_install_lnmp
<b>一键安装php</b>，目前针对默认安装的是php7！<br>
目前在ubuntu15.10和centos7中进行过测试，可以成功安装！<br>
<b>使用简介<b>
<b>一 给脚本执行权限<b>
进入你的one_shell_install_lnmp的git目录下面，执行如下命令：<br>
chmod a+x ubuntu_lnmp_init.sh<br>
或者<br>
chmod a+x centos7_lnmp_init.sh<br>
二 执行脚本<br>
./ubuntu_lnmp_init.sh
或者<br><
./centos7_lnmp_init.sh<br>
<br>
默认php的安装位置在/usr/local/php,所以无论是centos7还是ubuntu15*最好用root权限去运行，最后向/etc/profile中加入PHPRC必须需要root权限。如果觉得没必要刻可以自行注意掉那部分逻辑即可！
