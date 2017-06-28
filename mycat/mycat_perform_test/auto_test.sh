#!/bin/bash

. ./mysql_conf
s_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
python_web_data="/home/helingyun/hly_script/python/web_test/data_photo"


record_log() {
  echo "==============================================================================" | tee -a ${s_dir}/log/test_log
  echo "`date +%Y-%m-%d` `date +%H:%M:%S` $1" | tee -a ${s_dir}/log/test_log
}

pre_check() {
  test $UID != 0 && echo "please running the script by root, exit" && exit 1 
  if [ ! -d "back_log" ]; then
    mkdir back_log
    test $? != 0 && echo "mkdir back_log dir failed, exit..." && exit 1
  fi
  if [ ! -d "log" ]; then
    mkdir log
    test $? != 0 && echo "create log dir failed, exit..." && exit 1
  fi
}

cope_autotest_avgdata_to_csv() {
  csv_filename=mysql_${lua%.*}_`date +%H%M%S`.csv
  mysql_res_array=($(cut -f1 ${s_dir}/back_log/${temp_mysql_avg_filename}))
  mycat_res_array=($(cut -f1 ${s_dir}/back_log/${temp_mycat_avg_filename}))

  if [[ ${#mysql_res_array[@]} != ${mycat_res_array[@]} ]];then
    echo "error, mysql and mycat result data numbers was different" && exit 1
  fi

  lines_name="#"
  for((i=0; i<${#test_type[@]}; i++));do
    lines_name="${lines_name}${test_type[i]};"
  done
  echo "${lines_name%?}" >> ${s_dir}/${csv_filename} 

  for((i=0; i<${#mysql_res_array[@]}; i++));do
    echo "${mysql_res_array[i]};${mycat_res_array[i]}" >> ${s_dir}/${csv_filename}
  done
}

cope_csv_to_photo() {
  mv ${s_dir}/${csv_filename} ${python_web_data}
  python ${python_web_data}/../generate_photo.py ${csv_filename} logarithm
}

auto_test() {
  for lua in ${test_lua[@]}; do
    for te_type in ${test_type[@]}; do
      record_log "start type ${te_type} ${lua}"
      is_run=1

      file_name=${te_type}_`date +%H%M%S`_${lua}
      ./com_code.sh ${lua} ${te_type}
      # check the child script is end..
      while ((1));do
        is_run=`ps aux| grep -w "com_code.sh"| grep -v "grep"| wc -l`  
        test $is_run == 0 && break
        echo "com_code.sh is running..."
        sleep 1
      done
      
      # cope the test_log and delete blank lines
      grep -v "#" ${s_dir}/log/real_time_data | tr -s '\n' > ${s_dir}/back_log/${file_name}_rt
      cp ${s_dir}/log/avg_res ${s_dir}/back_log/${file_name}_avg
      
      if [[ ${te_type} == "mysql" ]]; then
        temp_mysql_avg_filename=${file_name}_avg
        temp_mysql_rt_filename=${file_name}_rt
      else
        temp_mycat_avg_filename=${file_name}_avg
        temp_mycat_rt_filename=${file_name}_rt        
      fi
      
      record_log "finished type ${te_type} ${lua}"
    done
    cope_autotest_avgdata_to_csv
    cope_csv_to_photo
  done
}

main() {
  pre_check
  auto_test
}

main
