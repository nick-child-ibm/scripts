#!/bin/bash

# this script will run a local failover every interval

device=$1
device=$(ofpathname ${device} | awk -F@ '{print $2}')
interval=40

for i in {1..100}
do
printf "Doing iteration : $i\nStarting failover\n"
dmesg -C
#run failover
echo 1 > /sys/devices/vio/${device}/failover
# wait for failover to complete
dmesg | grep "Done processing resets" > /dev/null;

while [ $? -eq 1 ];do
	printf "failover in progress\n";
	sleep 0.5;
	dmesg | grep "Done processing resets" > /dev/null;
done

printf "failover complete\n"

((i=i+1))
sleep $interval
done
