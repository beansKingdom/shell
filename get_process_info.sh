#!/bin/bash
#################################################
#get cpu/mem/io by pid (net??)
#################################################

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ./common_share_func.sh

####function_code
##get_process_mem
get_mem() {
  pidstat -r -p ${pid} ${interval_time} ${number} >> ${script_dir}/${p_name}_mem.log &
}

##get_process_cpu
get_cpu() {
  pidstat -u -p ${pid} ${interval_time} ${number} >> ${script_dir}/${p_name}_cpu.log &
}

##get_process_io
get_io() {
  pidstat -d ${interval_time} -p ${pid} ${number} >> ${script_dir}/${p_name}_io.log &
}

get_io_data() {
  #grep Actual test.log | awk 'BEGIN {print "read write"} {print $4,$10}'
  return 0
}

Usage() {
  echo "Usage :$0 pid count_num interval_time"
  echo "example $0 3306 150 1"
  exit  
}

main() { 
  get_io 
  get_cpu
  get_mem
}

check_input() {
  if [[ $2 =~ ^[1-9][0-9]{0,}$ ]] && [[ $1 =~ ^[1-9][0-9]{0,}$ ]] && [[ $3 =~ ^[1-9][0-9]{0,}$ ]];then
    pid=$1 && number=$2 && interval_time=$3
  else
    echo "input error, pid or count_num or interval_time not a num" && exit 1
  fi
}

if [[  $# < 3 ]];then
  Usage
fi

check_input $1 $2 $3

#get_process_name
test ! -e /proc/${pid}/status && echo "Can't found /proc/${pid}/status: No such file or directory, exit..." && exit 1
p_name=`cat /proc/${pid}/status | grep Name | awk '{print $2}'`_${pid}

echo '' > ${script_dir}/${p_name}_io.log && echo '' > ${script_dir}/${p_name}_cpu.log && echo '' > ${script_dir}/${p_name}_mem.log
test $? != 0 && echo "clean data_file failed,please check pid value, exit..." && exit 1 

check_server_version
is_install_check "sysstat" "iotop"

main 
echo "`date` begin to collect data--------------------------------" 
let sleep_time=interval_time*number
sleep $sleep_time
echo "`date` task finished--------------------------------" 
