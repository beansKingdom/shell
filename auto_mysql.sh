#!/bin/bash

scriptsdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ./auto_mysql_func.sh

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 == "" ]];then
  usage
fi

port=$1
DIR=$2
package_dir=$3
user='action'
passwd='action'

echo "install start...####################################################################################" > ${scriptsdir}/install_mysql.log 2>&1
###check_relay_software

###check_privilege...
check_user_privilege

###check_group_and_user
check_mysql_group_and_user

#check_software

#cp_mysql_file
cd ${DIR}
cp -r ${package_dir}/* ${DIR} 2>> ${scriptsdir}/install_mysql.log 
test ! -e my.cnf && echo "${DIR}/my.cnf is not exist, exit..." && exit 1
echo "skip-grant-tables" >> ${DIR}/my.cnf

test $? != 0 && echo "cp ${package_dir} to ${DIR} failed, see ${scriptsdir}/install_mysql.log for more details" && exit 1

#start install mysql
install_5_7_mysql 

#check mysql start status
check_mysql_status

echo "change mysql password"
check_sock
cd $scriptsdir
expect change_pw.exp root "${port}"  >> ${scriptsdir}/install_mysql.log 2>&1
sed -i '/skip-grant-tables/d' ${DIR}/my.cnf
kill_mysql

cd ${DIR}
echo 'start mysql...'
bin/mysqld_safe --defaults-file=${DIR}/my.cnf --user=mysql & >> ${scriptsdir}/install_mysql.log 2>&1
sleep 5s
echo  "restarted mysql successful..."

check_sock
cd $scriptsdir
expect change_pw_ag.exp root "${port}"  >> ${scriptsdir}/install_mysql.log 2>&1

check_sock
mysql -u ${user} -p${passwd} -P${port} -S /tmp/mysql_${port}.sock -e "flush privileges;" >> ${scriptsdir}/install_mysql.log 2>&1

echo "alias mysql${port}='mysql -u ${user} -p${passwd} -P${port} -h 127.0.0.1'" >> ~/.bashrc
sleep 3s
source ~/.bashrc

echo "install finished..."
echo "install finished...####################################################################################" >> ${scriptsdir}/install_mysql.log 2>&1
exit 0