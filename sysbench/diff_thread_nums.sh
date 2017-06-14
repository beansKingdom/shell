#!/bin/bash
# author Helingyun 

s_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

usage(){
  echo "==================================================="
  echo "change the script default config "
  echo "Script is used to test different thread load"
  echo "Load_type contact select/oltp_only_read/update/oltp_mix"
  echo "Usage : $0 load_type"
  echo "        example $0 select"
}

########################################################
# Change the default config                            #
########################################################
sysbench_dir=$s_dir/../sysbench
host_ip='10.186.17.101'
port=3306
user='action'
passwd='action'
dbname='test_mysql'
threads=(1 4 8 16 32 64 128 256 384 512)
test_time=60
tb_count=2
tb_size=50000000
########################################################

same_sys_commond="--mysql-table-engine=innodb --mysql-user=$user \
--mysql-password=$passwd --max-requests=0  --max-time=$test_time --oltp-tables-count=$tb_count --report-interval=1 \
--oltp-table-size=$tb_size --mysql-host=$host_ip --mysql-db=$dbname --mysql-port=$port --percentile=99"

select_func(){
  for thread in ${threads[@]};do
    ./sysbench --test=../db/select.lua  --num-threads=$thread $same_sys_commond run >> $s_dir/test_select.log 
    sleep 10
  done
}

mix_func(){
  for thread in ${threads[@]};do
    ./sysbench --test=../db/oltp.lua $same_sys_commond --num-threads=$thread --oltp-read-only=$is_only_read  \
--mysql-ignore-errors=1062  run >> $s_dir/test_oltp.log 
    sleep 30
  done
}

update_func(){
  for thread in ${threads[@]};do
    ./sysbench --test=../db/update_non_index.lua --num-threads=$thread $same_sys_commond \
--mysql-ignore-errors=1062  run >> $s_dir/test_update.log    
    sleep 30
  done
}

main() {
  cd $sysbench_dir 
  if (($# != 1));then 
    usage
    exit 1
  fi
  case "$1" in 
    select)
          select_func
          exit 0 ;;
    update)
          update_func
          exit 0 ;;
    oltp_only_read)
          is_only_read="on"
          mix_func
          exit 0 ;;
    oltp_mix)
          is_only_read="off"
          mix_func
          exit 0 ;;
    *)
          usage
          exit 1 ;;
  esac
}

main $1