#!/bin/bash

if [[ $# != 1 ]];then
  echo "Usage  :$0 port"
  echo "example:$0 3306"
  exit 1
fi

port=$1
mysql_dir=/data/mysql${port}

if [[ ! ${port} =~ ^[1-9][0-9]{0,}$  ]];then
  echo "port must be num..."
  exit 1
fi

cd ${mysql_dir}
#start mysql${port}
bin/mysqld_safe  --defaults-file=${mysql_dir}/my.cnf --user=mysql &

