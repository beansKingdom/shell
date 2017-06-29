#!/bin/bash

. ./common_share_func.sh

########################################################
# Change the default config                            #
########################################################
mycat_user="action"
mycat_passwd="action"
mycat_hostip="10.186.17.107"
mycat_port=8066
ftp_server_hostip="10.186.18.25"
ftp_username="ftp"
ftp_passwd="ftp"
ftp_package_dir="/home/ftpuser/actiontech-mycat/qa/2.17.04.0/"
mycat_install_dir="/home/helingyun"
package_name="actiontech-mycat.tar.gz"
########################################################

cd ${mycat_install_dir}
test $? != 0 && echo "Not found ${mycat_install_dir}, exit..." && exit 1

get_mycat_version() {
  mycat_version=`mysql -u$mycat_user -p$mycat_passwd -P$mycat_port -h $mycat_hostip -e "select version();"|grep mycat`
}

print_split() {
  awk 'BEGIN{for(i=0;i<100;i++) printf "="; printf "\n"}'
}

get_ftp_tar() {
echo "start to get software package from ftp, wait..."
ftp -n<<!
  open "$ftp_server_hostip"
  user "$ftp_username" "$ftp_passwd"
  binary
  cd "$ftp_package_dir"
  lcd "$mycat_install_dir"
  prompt
  mget *
  close
  bye
!
}

check_mycat_status() {
  status=`mycat status`
  if [[ $status =~ "not running" ]];then
    echo "mycat not running, can't get mycat version..."
  else
    get_mycat_version
    test $? != 0 && echo "get mycat version failed,please check script's mycat_config or mysql" && return 1
    echo "mycat version is $mycat_version"
  fi
}

print_split
check_mycat_status
check_server_version
is_install_check "ftp"

print_split
get_ftp_tar 2>> /dev/null
tar -zxvf actiontech-mycat.tar.gz >> /dev/null 2>&1
test $? != 0 && echo "tar package failed, exit..." && exit 1
#sed -i 's/MaxDirectMemorySize=2G/MaxDirectMemorySize=10G/g' ${mycat_install_dir}/mycat/conf/wrapper.conf
echo "wrapper.java.additional.12=-agentpath:/opt/libyjpagent.so=disablestacktelemetry,disableexceptiontelemetry,delay=10000" >> ${mycat_install_dir}/mycat/conf/wrapper.conf

print_split
echo "begin to restart mycat" 
${mycat_install_dir}/mycat/bin/mycat restart >> /dev/null
rm -rf actiontech-mycat.tar.gz

sleep 5
print_split
check_mycat_status
