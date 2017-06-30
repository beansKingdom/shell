#!/bin/bash

tc qdisc  del dev eno1 root
tc qdisc  add dev eno1 root handle 1: htb
tc class  add dev eno1 parent 1:1 classid 1:10 htb rate 20mbit ceil 20mbit
tc qdisc  add dev eno1 parent 1:10 sfq perturb 10
tc filter add dev eno1 protocol ip parent 1: u32 match ip dst 192.188.1.117 flowid 1:10

