#!/bin/bash
# author Helingyun 

usage(){
  echo "This script used to monitor cpu/mem/io/net/sys_err and so on" 
  echo "Usage : $0 counts interval_time"         
  echo "        counts : The total collection number"                       
  echo "        interval_time : The time interval between data collection"   
  echo "        example $0 10 1"                                                         
}

s_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if (($# != 2));then 
  usage
  exit 1
fi
 
count_num=$1
interval_time=$2
let sleep_time=count_num*interval
let temp=count_num+1

## check tool is install?? and user's privilege is root 
tool_in=`rpm -qa |grep sysstat* | grep sys |wc -l`
if (( $tool_in == 0 ));then
  echo "no install sysstat tool, exit...."
  exit 1
fi

## mkdir log dir
if [[ ! -d "$s_dir/monitor_log" ]]; then 
  mkdir "$s_dir/monitor_log"
  if (( $? != 0 ));then 
    echo "mkdir: cannot create directory 'monitor_log': Permission denied ...exit"
	exit 1
else 
  rm -rf $s_dir/monitor_log/*
  if (( $? != 0 ));then 
    echo "cannot remove monitor_log's file: Permission denied ...exit"
	exit 1  
fi 

## monitor_function
com_uptime() {
  for ((i=0;i<$count_num;i++));do
    uptime >> $s_dir/monitor_log/uptime.log
    sleep $interval_time
  done
}

com_dmesg() {
  for ((i=0;i<$count_num;i++));do
    echo "`date` ===================================" >> $s_dir/monitor_log/dmesg.log
    dmesg  | tail -n 50 >> $s_dir/monitor_log/dmesg.log
    sleep $interval_time
  done
}

com_vmstat() {
  vmstat -t $interval_time "${count_num}" >> $s_dir/monitor_log/vmstat.log
}

com_mpstat() {
  mpstat -P ALL $interval_time "${count_num}" >> $s_dir/monitor_log/mpstat.log
}

com_pidstat() {
  pidstat $interval_time "${count_num}" >> $s_dir/monitor_log/pidstat.log
}

com_iostat() {
  iostat -xzt $interval_time "${temp}" >> $s_dir/monitor_log/iostat.log
}

com_mem() {
  pidstat -r $interval_time "${count_num}" >> $s_dir/monitor_log/mem.log
}

com_sar_dev() {
  sar -n DEV $interval_time "${count_num}" >> $s_dir/monitor_log/sar_dev.log
}

com_sar_tcp_etcp() {
  sar -n TCP,ETCP $interval_time "${count_num}" >> $s_dir/monitor_log/sar_tcp_etcp.log
}

collect_cpu_hz() {
  for ((i=0;i<$count_num;i++));do
    echo `date` "num:$i=========================" >> $s_dir/monitor_log/cpu_hz.log
    cat /proc/cpuinfo | grep "MHz" >> $s_dir/monitor_log/cpu_hz.log
    echo `date` "num:$i=========================" >> $s_dir/monitor_log/cpu_hz.log
    sleep $interval_time
  done
}

main() {
com_uptime &
com_dmesg &
com_vmstat &
com_mpstat &
com_pidstat &
com_iostat &
com_mem &
com_sar_dev &
com_sar_tcp_etcp &
#collect_cpu_hz &
sleep "${sleep_time}"
}

main
exit 0
