#!/bin/bash

. ./common_share_func.sh

########################################################
# Change the default config                            #
########################################################
mycat_user="action"
mycat_passwd="action"
mycat_hostip="10.186.17.107"
mycat_port=8066
hostip="10.186.18.25"
username="ftp"
password="ftp"
ftp_package_dir="/home/ftpuser/actiontech-mycat/qa/2.17.04.0/"
local_dir="/home/helingyun"
########################################################

cd ${local_dir}
test $? != 0 && echo "Not found ${local_dir}, exit..." && exit 1

get_mycat_version() {
  ver=`mysql -u$mycat_user -p$mycat_passwd -P$mycat_port -h $mycat_hostip -e "select version();"|grep mycat`
}

print_split() {
  awk 'BEGIN{for(i=0;i<100;i++) printf "="; printf "\n"}'
}

get_ftp_tar() {
echo "start to get software package from ftp, wait..."
ftp -n<<!
  open "$hostip"
  user "$username" "$password"
  binary
  cd "$ftp_package_dir"
  lcd "$local_dir"
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
    test $? != 0 && echo "get mycat version failed,please check script's mycat_config is correct" && return 1
    echo "mycat version is $ver"
  fi
}

print_split
check_mycat_status
check_server_version
check_install_dep "ftp"

print_split
get_ftp_tar 2>> /dev/null
tar -zxvf actiontech-mycat.tar.gz >> /dev/null 2>&1
test $? != 0 && echo "tar package failed, exit..." && exit 1
sed -i 's/MaxDirectMemorySize=2G/MaxDirectMemorySize=10G/g' ${local_dir}/mycat/conf/wrapper.conf

print_split
echo "begin to restart mycat" 
${local_dir}/mycat/bin/mycat restart >> /dev/null
rm -rf actiontech-mycat.tar.gz

sleep 5
print_split
check_mycat_status
