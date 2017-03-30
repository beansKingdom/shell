#!/bin/bash

usage() {
  echo "Usage: $0 port mysql_install_dir mysql_package_dir"
  echo "example: $0 3306 /data/mysql3306 /home/mysql-5.7.11-linux-glibc2.5-x86_64" && exit 1
}

check_user_privilege() {
  if [[ $UID != 0 ]];then 
    echo "Permission denied,script must runing by root"
        exit 1
  fi
  test -d ${DIR} && echo "${DIR} is exist,exit..."  && exit 1
  mkdir -p "${DIR}" 2>> ${scriptsdir}/install_mysql.log
  test $? != 0 && echo "mkdir ${DIR} failed, see ${scriptsdir}/install_mysql.log for more details" && exit 1
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


kill_mysql (){
  let is_kill=0
  while (($is_kill == 0));do
    ps aux|grep "$DIR" |egrep -v "grep|install_mysql\.log|\.sh" | awk '{print $2}' > ${scriptsdir}/softpid.txt
    num=`cat ${scriptsdir}/softpid.txt|wc -l`
    if [[ $num > 0 ]];then
      echo 'mysql is exists...'
      A=($(cut -f1 ${scriptsdir}/softpid.txt))
      for((i=0;i<${#A[@]};i++));do
         kill -9 ${A[i]}
      done
      sleep 5s
    else
      echo 'mysql is killed...'
      let is_kill++
    fi
  done
}

check_software (){
  let in_software=0
  while (($in_software == 0));do
    in_openssl=`rpm -qa | grep openssl |grep -v "openssl-libs" |wc -l`
    in_expect=`rpm -qa | grep expect | wc -l`
    if [[ $in_openssl == 0 ]];then
      echo 'install relay_software openssl...'
      ##yum -y install openssl >>  ${DIR}/install_mysql.log 2>&1
       apt-get install openssl
    elif [[ $in_expect == 0 ]]; then
      echo 'install relay_software expect...'
      ##yum -y install expect >> ${DIR}/install_mysql.log 2>&1 
       apt-get install expect
    else
      let in_software++
      echo 'relay_software is ok...'
    fi
    sleep 5s
  done
}

check_mysql_group_and_user() {
  egrep "mysql" /etc/group >& /dev/null  
  test $? != 0 && groupadd mysql 

  egrep "mysql" /etc/passwd >& /dev/null  
  test $? != 0 && useradd -r -g mysql  mysql 
}

install_5_7_mysql() {
  mkdir mysql-files
  mkdir ${DIR}/data
  chmod 750 mysql-files
  chown -R mysql .
  chgrp -R mysql .
  id=`date +%s`
  sed -i "s:server_id.*=.*:server_id                      = ${id}:g" my.cnf
  sed -i "s:port.*=.*:port                           = ${port}:g" my.cnf
  sed -i "s:basedir.*=.*:basedir                        = ${DIR}:g" my.cnf
  sed -i "s:datadir.*=.*:datadir                        = ${DIR}/data:g" my.cnf
  sed -i "s:socket.*=.*:socket                         = /tmp/mysql_${port}.sock:g" my.cnf
  #sed -i "s///g" my.cnf
  bin/mysqld --initialize --basedir=${DIR} --datadir=${DIR}/data --innodb-data-file-path=ibdata1:256M:autoextend --user=mysql >> ${scriptsdir}/install_mysql.log 2>&1
  sleep 5s
  # bin/mysql_ssl_rsa_setup --defaults-file=${DIR}/my.cnf >> ${scriptsdir}/install_mysql.log 2>&1
  echo 'start mysql...'
  bin/mysqld_safe --defaults-file=${DIR}/my.cnf & >> ${scriptsdir}/install_mysql.log 2>&1
  sleep 5s
  if [[ ! -e "/usr/bin/mysql" ]];then
    ln -s ${DIR}/bin/mysql /usr/bin/mysql >> ${scriptsdir}/install_mysql.log 2>&1
  fi
}

check_mysql_status() {
  count=0
  while ((1));do
    mysql -uroot -ptest -P${port} -S /tmp/mysql_${port}.sock -e "show databases;" >> /dev/null 2>>${scriptsdir}/install_mysql.log
    test $? == 0 && echo "mysql is running" && break
    echo "mysql is not running, wait 5s"
    test $count -gt 3 && echo "mysql start failed. exit..." && exit 1
    let count++
    sleep 5
  done
}