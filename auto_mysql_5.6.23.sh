#!/bin/bash

scripts_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ./mysql_func.sh
. ./common_share_func.sh

port=$1
mysql_install_dir=$2
mysql_package_dir=$3

######################################################################

if [[ $@ < 2 ]];then
  Usage
fi

print_split
check_mysql_group_and_user
check_mysql_dir
cp_mysql_file
install_pre
change_mycnf

print_split
echo "start to install mysql...wait"
scripts/mysql_install_db --defaults-file=${mysql_install_dir}/my.cnf --user=mysql >> /dev/null
bin/mysqld_safe --defaults-file=${mysql_install_dir}/my.cnf & >> /dev/null

if [[ ! -e "/usr/bin/mysql" ]];then
  ln -s ${mysql_install_dir}/bin/mysql /usr/bin/mysql >> ${scriptsdir}/install_mysql.log 2>&1
fi
sleep 10s

check_sock
print_split
echo "change mysql password"
expect ${scripts_dir}/change_pw.exp "root" "${port}" >> /dev/null
sleep 10s

check_sock
sed -i '/skip-grant-tables/d' ${mysql_install_dir}/my.cnf
expect ${scripts_dir}/change_pw_ag.exp "root" "${port}" >> /dev/null

sleep 5s
check_sock
mysql -uaction -paction -h127.0.0.1 -P${port} -e "show databases;" >> /dev/null
test $? != 0 && echo "add user to mysql failed, exit..." && exit 1

add_alias=`grep  "\-P${port}" ~/.bashrc|wc -l`
if [[ $add_alias == 0 ]];then
  echo "alias mysql${port}='mysql -uaction -paction -P${port} -h 127.0.0.1'" >> ~/.bashrc && source ~/.bashrc 
fi

print_split
echo "install ok....."
