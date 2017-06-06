#!/bin/bash

. mysql_conf
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

## default config 
sysbench_dir=/home/helingyun/sysbench/sysbench
#threads=(1 4 8 16 32 64 128 256 384 512 1024 1536 2048)
threads=(1)
each_test_runtime=30
table_count=1
table_row=100000000
warm_up_sleep_time=10
warm_up_run_time=300
warm_up_thread_nums=2048

Usage() {
  echo "The script is used to test mycat and mysql"
  echo "  example $0 script.lua config_type(mysql/mycat)"
  echo "  example $0 test.lua mysql" && exit 1
}

judge_run_test_type() {
update_lua=('mycat_update_same.lua')
select_lua=('mycat_select.lua' 'mycat_select_in.lua' 'mycat_select_order.lua' 'mycat_select_between.lua' 'mycat_select_group_having.lua')
insert_lua=('mycat_insert.lua')

for lua in ${update_lua[@]};do
  if [[ ${lua_script_name} == ${lua} ]];then
    run_test_type="update_test"
    return 0
  fi
done

for lua in ${select_lua[@]};do
  if [[ ${lua_script_name} == ${lua} ]];then
    run_test_type="select_test"
    return 0
  fi
done

for lua in ${insert_lua[@]};do
  if [[ ${lua_script_name} == ${lua} ]];then
    run_test_type="insert_test"
    return 0
  fi
done
}

config_init() {
  ## check the config type, and get config
  if [[ $config_type == "mysql" ]];then
    host_ip=${mysql_host_ip} && dbname=${mysql_dbname} && port=${mysql_port} && user=${mysql_user} && passwd=${mysql_passwd}
  elif [[ $config_type == "mycat" ]];then
    host_ip=${mycat_host_ip} && dbname=${mycat_dbname} && port=${mycat_port} && user=${mycat_user} && passwd=${mycat_passwd}  
  else 
    echo "Error config type input, only mysql or mycat. exit..." && exit 1
  fi
}

warm_up_data() {
  echo "" > ${script_dir}/log/warmup_log
  ./sysbench --test=../db/${lua_script_name} --num-threads=${warm_up_thread_nums} ${same_command} --max-time=${warm_up_run_time} --mysql-ignore-errors=1062  run >> ${script_dir}/log/warmup_log
  sleep ${warm_up_sleep_time}
}

perform_test_prepare() {
  echo "`date +%Y-%m-%d` `date +%H:%M:%S`  begin ${run_test_type}" | tee -a ${script_dir}/log/mycat_perform_test.log
  cd ${sysbench_dir} 
  
  if [[ ${run_test_type} != "insert_test" ]];then
      #warm_up_data 
      echo "warm_up_data"
  fi
}

perform_test() {
  perform_test_prepare
  echo "" > ${script_dir}/log/temp_log
  for thread in ${threads[@]};do
    echo "`date +%Y-%m-%d` `date +%H:%M:%S` start load $thread=================================" >> $script_dir/log/temp_log
    ./sysbench --num-threads=${thread} ${same_command} ${expand_command} run >> $script_dir/log/temp_log
    sleep 5
    if [[ ${run_test_type} == "insert_test" ]];then
      mysql -u${user} -p${passwd} -P${port} -h${host_ip} -e "use ${dbname}; truncate ${insert_table_name};"
    fi
  done
}

select_test() {   
  expand_command=""
  perform_test
  result_deal
}

insert_test() {
  expand_command="--auto-inc=0"
  insert_table_name="send_list"
  perform_test
  result_deal
}

update_test() {
  expand_command=""
  perform_test
  result_deal
}

result_deal() {
  if [[ ${run_test_type} == "select_test" ]];then
    grep "threads:" $script_dir/log/temp_log |awk '{print $8}' | awk -F "," '{print $1}' > $script_dir/log/real_time_data
  else 
    grep "threads:" $script_dir/log/temp_log |awk '{print $10}' | awk -F "," '{print $1}' > $script_dir/log/real_time_data
  fi
  grep "read/write" $script_dir/log/temp_log | awk '{print $4}' |awk -F "(" '{printf "%s\t",$2}' > $script_dir/log/avg_res
}

main() {
  judge_run_test_type
  config_init
  same_command="--mysql-table-engine=innodb --mysql-user=$user --mysql-password=$passwd --max-requests=0 --oltp-tables-count=$table_count --max-time=${each_test_runtime} \
  --report-interval=1 --test=../db/${lua_script_name} --oltp-table-size=$table_row --mysql-host=$host_ip --mysql-db=$dbname --mysql-ignore-errors=1062 --mysql-port=$port "

  case "$run_test_type" in 
    update_test)
      update_test
      return 0;;
    select_test) 
      select_test
      return 0;;
    insert_test) 
      insert_test
      return 0;;
    *)
      echo "not found the lua_name in sysbench/db dir, exit..."
      exit 1;;
  esac
}

if [ $# != 2 ] || [ $1 == '-h' ] || [ $1 == '-help' ];then
  Usage
fi

lua_script_name=$1
config_type=$2
main 
