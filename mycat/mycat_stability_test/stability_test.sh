#!/bin/bash

scripts_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

thread_num=(4 8 16 32 50 64 128 150 190 256 300 384 512 789 900 1024 1536 1800 2048 2200 2400 3000 3500 3800)
sysbench_dir="/usr/local/hly/sysbench-0.5"
echo '' > ${scripts_dir}/test_st.log 

check_child_task() {
  child_pid=$1
  is_exist=`ps aux|grep $1|grep -v "grep"|wc -l`
  if [[ ${is_exist} == 0 ]];then
    let temp--
  fi
}

check_log_info() {
  is_err=`grep -w "error" ${scripts_dir}/test_st.log|wc -l`
  test $is_err == 0 && return 0
  send_error_mail  
}

send_error_mail() {
  get_local_server_ip
  generate_mail_message
  python ${scripts_dir}/send_mail.py ${message}
  exit 1
}

get_local_server_ip() {
  echo '' > ${scripts_dir}/ip_temp.log
  ip_result=($(ifconfig | grep inet | grep -v "127.0.0.1" | grep -v "inet6"))

  for res in ${ip_result[@]};do
    if [[ $res =~ [0-9\.]{1,}$ ]];then
      echo ${res#*:} >> ${scripts_dir}/ip_temp.log
    fi
  done

  sed -i "/\.*255$/g"  ${scripts_dir}/ip_temp.log
  sed -i "/\.0$/g" ${scripts_dir}/ip_temp.log
  cat ${scripts_dir}/ip_temp.log | sed -e '/^$/d' > ${scripts_dir}/ip_temp_1.log
  rm -rf ${scripts_dir}/ip_temp.log
}

generate_mail_message() {
  message=""
  array=($(cut -f1 ${scripts_dir}/ip_temp_1.log))
  for result in ${array[@]};do
    message="${message} ${result}"
  done
  return 0
}

tar_test_log() {
  log_size=`ls -l ${scripts_dir}/test_st.log |awk '{print $5}'`
  if (("${log_size}" > 10485760 )); then
    cd ${scripts_dir}
    tar zcvf test_st_`date +%Y%m%d%H%M%S`.log.tar.gz test_st.log >> /dev/null
    sleep 1
    echo '' > ${scripts_dir}/test_st.log
  fi
  return 0
}

main() {
while((1));do
  #generate random load
  thread_num_length=${#thread_num[@]}
  random_thread_nums=($(seq 1 ${thread_num_length}|shuf))
  
  cd ${sysbench_dir}/sysbench
  for j in ${random_thread_nums[@]};do
    let j--
    echo "`date +%Y-%m-%d` `date +%H:%M:%S:%N` start thread_nums:${thread_num[$j]} load =======================" >> ${scripts_dir}/test_st.log
    ./sysbench --test=../db/stability.lua --rand-type=uniform --mysql-user=action --mysql-password=action --mysql-port=8066 \
    --mysql-host=10.186.21.143 --mysql-db=hly_test  --max-requests=0  --max-time=100 --num-threads=${thread_num[$j]} \
    --report-interval=1 --oltp_tables_count=2 --oltp-table-size=200000000  run >> ${scripts_dir}/test_st.log &
    sleep 105 && temp=1
    
    while ((${temp}));do
      check_child_task "$!"
      check_log_info
      sleep 5
    done
    echo "" >> ${scripts_dir}/test_st.log
    
    tar_test_log
    #cd ${sysbench_dir}/sysbench
  done
done
}

main
