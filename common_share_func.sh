#!/bin/bash

scripts_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

print_split() {
  awk 'BEGIN{for(i=0;i<100;i++) printf "="; printf "\n"}'
}

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