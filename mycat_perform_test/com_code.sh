#!/bin/bash

. mysql_conf            # import mysql config

s_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

Usage() {
  echo "The script is used to test mycat and mysql"
  echo "lua_name : lua script name, it will find the lua_name script in sysbench/db"
  echo "test_type: it's decide the script get which type config value in mysql_conf"
  echo "  example $0 lua_name test_type(mysql/mycat)"
  echo "  example $0 test.lua mysql" && exit 1
}

# Usage example
if [ $# != 2 ] || [ $1 == '-h' ] || [ $1 == '-help' ];then
  Usage
fi

warmup_fun() {
  echo "" > $s_dir/log/warmup_log
  ./sysbench --test=../db/$1 --num-threads=2048 ${same_com} --max-time=300 \
--mysql-ignore-errors=1062  run >> $s_dir/log/warmup_log
  sleep 10
}

config_init() {
  #check the test type, and get the config
  if [[ $test_type == "mysql" ]];then
    host_ip=${mysql_host_ip} && dbname=${mysql_dbname} && port=${mysql_port} && user=${mysql_user} && passwd=${mysql_passwd}
  elif [[ $test_type == "mycat" ]];then
    host_ip=${mycat_host_ip} && dbname=${mycat_dbname} && port=${mycat_port} && user=${mycat_user} && passwd=${mycat_passwd}  
  else 
    echo "error test type input, only mysql or mycat. exit..." && exit 1
  fi
# default config ##########################################
sysbench_dir=/home/helingyun/sysbench/sysbench
#threads=(1 4 8 16 32 64 128 256 384 512 1024 1536 2048)
threads=(1)
test_time=30
tb_count=1
tb_size=100000000
same_com="--mysql-table-engine=innodb --rand-type=uniform --mysql-user=$user --mysql-password=$passwd --max-requests=0 --oltp-tables-count=$tb_count --report-interval=1 --oltp-table-size=$tb_size --mysql-host=$host_ip --mysql-db=$dbname --mysql-port=$port "
}

check_test_type() {
update_lua=('mycat_update_same.lua')
select_lua=('mycat_select.lua' 'mycat_select_in.lua' 'mycat_select_order.lua' 'mycat_select_between.lua' 'mycat_select_group_having.lua')
insert_lua=('mycat_insert.lua')

for lua in ${update_lua[@]};do
  if [[ ${lua_script} == $lua ]];then
    lua_test_type=0
    return 0
  fi
done

for lua in ${select_lua[@]};do
  if [[ ${lua_script} == $lua ]];then
    lua_test_type=1
    return 0
  fi
done

for lua in ${insert_lua[@]};do
  if [[ ${lua_script} == $lua ]];then
    lua_test_type=2
    return 0
  fi
done
}

select_test() {
echo "begin select_test"
cd $sysbench_dir    
warmup_fun $lua_script

echo "" > $s_dir/log/temp_log
for thread in ${threads[@]};do
  echo "start load $thread=================================" >> $s_dir/log/temp_log
  ./sysbench --test=../db/${lua_script} --num-threads=${thread} ${same_com} --max-time=${test_time} \
--mysql-ignore-errors=1062  run >> $s_dir/log/temp_log
  sleep 5
done

grep "threads:" $s_dir/log/temp_log |awk '{print $8}' | awk -F "," '{print $1}' > $s_dir/log/real_time_data
grep "read/write" $s_dir/log/temp_log | awk '{print $4}' |awk -F "(" '{printf "%s\t",$2}' > $s_dir/log/avg_res
}

insert_test() {
echo "begin insert_test"
cd $sysbench_dir
echo "" > $s_dir/log/temp_log
for thread in ${threads[@]};do
  echo "start load $thread=================================" >> $s_dir/log/temp_log
  ./sysbench --test=../db/${lua_script} --num-threads=${thread} ${same_com} --max-time=${test_time} \
--mysql-ignore-errors=1062 --auto-inc=0  run >> $s_dir/log/temp_log
  sleep 3
  mysql -u${user} -p${passwd} -P${port} -h${host_ip} -e "use ${dbname}; truncate send_list;"
  sleep 3
done

grep "threads:" $s_dir/log/temp_log |awk '{print $10}' | awk -F "," '{print $1}' > $s_dir/log/real_time_data
grep "read/write" $s_dir/log/temp_log | awk '{print $4}' |awk -F "(" '{printf "%s\t",$2}' > $s_dir/log/real_time_data

}

update_test() {
echo "begin update_test"
cd $sysbench_dir    
warmup_fun $lua_script

echo "" > $s_dir/log/temp_log
for thread in ${threads[@]};do
  echo "start load $thread=================================" >> $s_dir/log/temp_log
  ./sysbench --test=../db/${lua_script} --num-threads=${thread} ${same_com} --max-time=${test_time} \
--mysql-ignore-errors=1062  run >> $s_dir/log/temp_log
  sleep 5
done

grep "threads:" $s_dir/log/temp_log |awk '{print $10}' | awk -F "," '{print $1}' > $s_dir/log/real_time_data
grep "read/write" $s_dir/log/temp_log | awk '{print $4}' |awk -F "(" '{printf "%s\t",$2}' > $s_dir/log/avg_res
}

main() {
config_init
check_test_type
   
# 0:update_test  1:select_test  2:insert_test
case "$lua_test_type" in 
  0)
    update_test
    return 0;;
  1) 
    select_test
    return 0;;
  2) 
    insert_test
    return 0;;
  *)
    echo "not found the lua_name in sysbench/db dir, exit..."
    exit 1;;
esac
}

lua_script=$1
test_type=$2
main 
