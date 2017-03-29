#!/bin/bash
# Script is used to generate alternating high and low pressure load
# You can chose the load type by alter the variable pressure_lua   
# author Helingyun 

s_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
########################################################
# change the default config                            #
########################################################
sysbench_dir=$s_dir/../sysbench
host_ip='127.0.0.1'
port=8066
user='action'
passwd='action'
dbname='hly_test'
tb_count=2
tb_size=100000000
pressure_lua='select.lua'
#pressure_lua=" --test=../db/oltp.lua"

########################################################################## 
# Don't change the default conf unless you understand all of the script  #
##########################################################################
high_pressure=1000
low_pressure=10
load_time=10
sleep_time=10
load_cycle_count=10
sysbench_commond="--mysql-db=$dbname --mysql-host=$host_ip --mysql-port=$port --mysql-table-engine=innodb --mysql-user=$user \
--mysql-password=$passwd --max-time=$load_time --max-requests=0 --percentile=99 --mysql-ignore-errors=1062 --report-interval=1 \
--oltp_tables_count=$tb_count --oltp-table-size=$tb_size --test=$sysbench_dir/../db/$pressure_lua "

high_load (){
  echo `date +%H:%M:%S` ==================start high load=============== >> $s_dir/load_high.log 
  ./sysbench $pressure_lua $sysbench_commond --num-threads=$high_pressure  run >> $s_dir/load_high.log 
  echo `date +%H:%M:%S` ==================finish high load=============== >> $s_dir/load_high.log
}

low_load (){
  echo `date +%H:%M:%S` ==================start low load=============== >> $s_dir/load_low.log
  ./sysbench $pressure_lua $sysbench_commond --num-threads=$low_pressure  run >> $s_dir/load_low.log 
  echo `date +%H:%M:%S` ==================finish low load=============== >> $s_dir/load_low.log
}

cd $sysbench_dir
echo "" > $s_dir/load_high.log 
echo "" > $s_dir/load_low.log

while (($load_cycle_count>0));do
  high_load 
  low_load 
  high_load 
  sleep $sleep_time
  let load_cycle_count=load_cycle_count-1
done