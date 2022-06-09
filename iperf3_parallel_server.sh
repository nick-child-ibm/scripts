#!/bin/bash

# This script runs iperf3 server in ${N_PROCESSES} parallel connections
# run with `quit` to turn off the servers, otherwise the ports will run 
# 	in the background forever!!!

# User can edit below
N_PROCESSES=8
START_PORT=5101

# User should not edit
if [ "$1" = "quit" ];
then
	printf "tearing down iperf3 servers\n"
	declare -a pids
	pids=`ps aguwx | grep iperf3 | grep -v grep | awk '{print $2}' |  xargs`
	#for pid in "${pids[@]:0}"
	#do
		printf "Killing $pids \n"
		kill $pids
	#done;
	exit 0
fi;
i=0
while [ $i -lt $N_PROCESSES ]
do
	iperf3 -s -p ${START_PORT} &
	START_PORT=$((START_PORT+1))
	i=$((i+1))
done
sleep 1
printf "REMEMBER TO USE '$0 quit' to turn off the iperf3 servers!!!\n\tYou can also use 'ps aguwx | grep iperf3' and kill process manually\n"
