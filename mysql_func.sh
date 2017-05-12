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
    fi
  done
}

check_mysql_group_and_user() {
  egrep "mysql" /etc/group >& /dev/null  
  test $? != 0 && groupadd mysql 

  egrep "mysql" /etc/passwd >& /dev/null  
  test $? != 0 && useradd -r -g mysql  mysql 
}

check_install_dep() {
  echo "pass"
}

check_mysql_dir() {
  if [[ ! -d ${mysql_install_dir} ]];then 
    sudo mkdir "${mysql_install_dir}"
  else
    echo "${mysql_install_dir} is exist,exit..." && exit 1
  fi
  
  if [[ ! -d ${mysql_package_dir} ]];then
    echo "Not found ${mysql_package_dir}, exit..." && exit 1
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

cp_mysql_file() {
  echo "cp mysql file to install dir...wait a minute"
  cd ${mysql_install_dir}
  cp -r ${mysql_package_dir}/*  ${mysql_install_dir}/
  test $? != 0 && echo "cp mysql_package to install dir failed, exit..." && exit 1
}

install_pre() {
  chmod 755 support-files/* scripts/*
  chown -R mysql .
  chgrp -R mysql .
  test $? != 0 && echo "Can't chown or chgrp ,Permission denied, exit..." && exit 1
  test ! -e my.cnf && echo "Can't find my.cnf file, exit..." && exit 1
}
