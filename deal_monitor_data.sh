#!/bin/bash
# Script deal the date which product by monitor_perf.sh
# It will create iostat_deal.txt cpu_deal.txt mem_deal.txt 
# author Helingyun 

usage (){
  echo "input args error..., "
  echo "$0 pid io_device_name"
  echo "example $0 3306 sda_1"
}

deal_iostat (){
  printf "%s\t%s\t%s\t%s\n" rkB/s wkB/s avgqu-sz %util >> ./iostat_deal.txt
  cat monitor_log/iostat.log | grep $io_disk | awk '{printf ("%d\t%d\t%d\t%d\n",$6,$7,$9,$14)}' >> ./iostat_deal.txt
}

deal_cpu (){
printf "%s\t%s\t%s\n" %usr %system %CPU >> ./cpu_deal.txt
cat monitor_log/pidstat.log |grep -w $pro_pid | awk '{printf ("%d\t%d\t%d\n",$4,$5,$7)}' >> ./cpu_deal.txt
}

deal_total_mem (){
cat monitor_log/mem.log | grep -w $pro_pid | grep -v Average | awk '{print $7}' >> ./mem_deal.txt
}

# deal_cpu_hz (){
  # cp log/cpu_hz.log ./hz.log
  # sed -i "s/cpu MHz//g" hz.log
  # sed -i "s/: //g" hz.log
  # sed -i "s/\t//g" hz.log
  # num=`cat hz.log |  tail -n 1| awk -F ":" '{print $4}' |awk -F "=" '{print $1}'`
  # for ((i=0;i<$num;i++));do
    # sed -n "/num:$i===/,/num:$i===/p" hz.log > each_cpu.log
    # fre=($(cat each_cpu.log | grep -v "=="))
    # length=${#fre[@]}
    # for((j=0;j<$length;j++));do
      # printf "%0.2f\t" ${fre[j]} >> data.log
    # done
    # printf "\n" >> data.log
  # done
# }

rm -rf *_deal.txt 
if (( $# != 2 ));then 
  usage
  exit 1
fi

pro_pid=$1
io_disk=$2

deal_iostat
deal_cpu 
deal_total_mem