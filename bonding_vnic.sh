#!/bin/bash

dev1=eth1
dev2=eth3
bond=bond1
bond_ip=110.1.194.237/24

echo +$bond > /sys/class/net/bonding_masters
sleep 1
echo 1 > /sys/class/net/${bond}/bonding/mode
sleep 1
echo 2 > /sys/class/net/${bond}/bonding/fail_over_mac
echo 100 > /sys/class/net/${bond}/bonding/miimon

sleep 1
echo "+${dev1}" > /sys/class/net/${bond}/bonding/slaves
echo "+${dev2}" > /sys/class/net/${bond}/bonding/slaves

ip link set  $dev1 up
ip link set  $dev2 up

sleep 1

ip addr add $bond_ip dev ${bond};ip link set ${bond} up


