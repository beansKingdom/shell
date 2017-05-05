#!/bin/bash

scripts_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

port=$1
mysql_install_dir=$2
#hostip=$3
mysql_package_dir=$3

######################################################################
Usage (){
  echo "input wrong..."
  echo "Usage:./1.sh port mysql_install_dir mysql_package_dir"
  echo "example ./sh 3317 /data/mysql1 /usr/local/hly/mysql"  
  exit
}

check_sock (){
  let j=0
  while (( $j == 0 ));do
    if [[ ! -e "/tmp/mysql_${port}.sock" ]];then
      echo "no sock,wait 10s"
      sleep 10
    else 
      let j++
      echo 'sock is exists...'
    fi
  done
}

check_mysql_group_and_user() {
  egrep "mysql" /etc/group >& /dev/null  
  test $? != 0 && groupadd mysql 

  egrep "mysql" /etc/passwd >& /dev/null  
  test $? != 0 && useradd -r -g mysql  mysql 
}

## 1:red hat 2:ubtun 3:suse
check_server_version() {
  version=`cat /proc/version |awk -F "[()]" '{print $5}'`
  if [[ $version =~ ^[Rr][Ee][Dd].* ]];then 
    version_type=1
  elif [[ $version =~ ^[Uu][Bb][Uu].* ]];then 
    version_type=2
  else 
    echo "ERROR not found server version..." && exit 1
  fi
}

check_install_dep() {
  echo "pass"
}

check_install_dir() {
  if [[ ! -d ${mysql_install_dir} ]];then 
    sudo mkdir "${mysql_install_dir}"
  else
    echo "${mysql_install_dir} is exist,exit..."
    exit
  fi
}

change_mycnf() {
  id=`date +%s`
  sed -i "s:server_id.*=.*:server_id                      = ${id}:g" my.cnf
  sed -i "s:port.*=.*:port                           = ${port}:g" my.cnf
  sed -i "s:basedir.*=.*:basedir                        = ${mysql_install_dir}:g" my.cnf
  sed -i "s:datadir.*=.*:datadir                        = ${mysql_install_dir}/data:g" my.cnf
  sed -i "s:socket.*=.*:socket                         = /tmp/mysql_${port}.sock:g" my.cnf
  echo "skip-grant-tables" >> ${mysql_install_dir}/my.cnf
#sed -i "s///g" my.cnf
}

if [[ $@ < 2 ]];then
  Usage
fi

check_mysql_group_and_user

check_install_dir

cd ${mysql_install_dir}
cp -r $mysql_package_dir/*  ${mysql_install_dir}/
test $? != 0 && echo "cp mysql_package to install dir failed, exit..." && exit 1

chmod 755 support-files/* scripts/*
chown -R mysql .
chgrp -R mysql .
test $? != 0 && echo "Can't chown or chgrp ,Permission denied, exit..." && exit 1

test ! -e my.cnf && echo "Can't find my.cnf file, exit..." && exit 1
change_mycnf

scripts/mysql_install_db --defaults-file=${mysql_install_dir}/my.cnf --user=mysql

bin/mysqld_safe --defaults-file=${mysql_install_dir}/my.cnf &

if [[ ! -e "/usr/bin/mysql" ]];then
  ln -s ${mysql_install_dir}/bin/mysql /usr/bin/mysql >> ${scriptsdir}/install_mysql.log 2>&1
fi
sleep 10s

check_sock
echo "change mysql password"
expect ${scripts_dir}/change_pw.exp "root" "${port}"
sleep 10s

check_sock
sed -i '/skip-grant-tables/d' ${mysql_install_dir}/my.cnf
expect ${scripts_dir}/change_pw_ag.exp "root" "${port}"

sleep 5s
check_sock
mysql -uaction -paction -h127.0.0.1 -P${port} -e "flush privileges;"
