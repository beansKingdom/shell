#!/bin/bash
# the script is kill process by port

if [[ $# != 1 ]];then
  echo "Usage  :$0 port"
  echo "example:$0 3306"
  exit 1
fi

port=$1

if [[ ! ${port} =~ ^[1-9][0-9]{0,}$  ]];then
  echo "port must be num..."
  exit 1
fi


#get the process pid
pid=$(netstat -anp|grep ${port} | grep "sock"|awk '{print $9}' |awk -F "/" '{print $1}')
#get the process name
p_name=$(netstat -anp|grep ${port} | grep "sock"|awk '{print $9}' |awk -F "/" '{print $2}')

while ((1));do
  echo "Make sure to kill program ${p_name}, pid is ${pid}(y/n)"
  read input
  if [[ ${input} == y ]] || [[ ${input} == Y ]];then
    break
  elif [[ ${input} == n ]] || [[ ${input} == N ]];then
    echo "script exit..."
    exit 0
  else
    echo "input error"
  fi
done

kill -9 ${pid}
