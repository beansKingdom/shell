#!/bin/bash
#################################################
#get cpu/mem/io by pid (net??)
#################################################

######collect prepare
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
Usage() {
  echo "Usage :$0 pid count_num interval_time(default 3)"
  echo "example $0 3306 150 1"
  exit  
}

if [[  $# < 2 ]];then
  Usage
fi

pid=$1
number=$2
if [[ $3 == '' ]];then 
  interval_time=3
else 
  interval_time=$3
fi

#get_process_name
p_name=`cat /proc/${pid}/status | grep Name | awk '{print $2}'`
test $? != 0 && exit 1

echo '' > ${script_dir}/${p_name}_io.log
echo '' > ${script_dir}/${p_name}_cpu.log
echo '' > ${script_dir}/${p_name}_mem.log

####function_code
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

is_install_check() {
  if [[ $version_type == 1 ]];then
    check_type="rpm -qa"
  else
    check_type="dpkg --get-selections"
  fi

  for i in $@;do
    temp_num=`$check_type | grep -w "^$i" | wc -l`
    test $temp_num = 0 && echo "Not found $i, please install it, exit..." && exit 1
  done
  
  echo "all tools were installed..."
}

##get_process_mem
get_mem() {
  pidstat -r -p ${pid} ${interval_time} >> ${script_dir}/${p_name}_mem.log &
}

##get_process_cpu
get_cpu() {
  pidstat -u -p ${pid} ${interval_time} >> ${script_dir}/${p_name}_cpu.log &
}

##get_process_io
get_io() {
  pidstat -d -p ${pid} ${interval_time} >> ${script_dir}/${p_name}_io.log &
}

get_io_data() {
  #grep Actual test.log | awk 'BEGIN {print "read write"} {print $4,$10}'
  return 0
}

check_server_version
is_install_check "iotop" "sysstat"

#echo "`date` begin to collect data--------------------------------" | tee "${script_dir}/date.log"
#printf "%-10s\t%-10s\t%-10s\t%-10s\n" Time cpu mem read_io write_io >> "${script_dir}/date.log"

main() { 
  get_io 
  get_cpu
  get_mem
}

main 
