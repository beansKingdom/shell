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