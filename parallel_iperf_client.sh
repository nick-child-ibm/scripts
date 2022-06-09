#!/bin/bash

# This script runs iperf3 client in ${N_PROCESSES} parallel connections
# Prior to running this, the server should be setup with the same ports open

# User can edit below
N_PROCESSES=8
START_PORT=5101
HOSTNAME="<server ip>"
TIME=120

# User should not edit
i=0
while [ $i -lt $N_PROCESSES ]
do
	iperf3 -t $TIME -T p$i -c $HOSTNAME -p ${START_PORT} -i 5 &
	START_PORT=$((START_PORT+1))
	i=$((i+1))
done
sleep 1
printf "REMEMBER TO USE '$0 quit' to turn off the iperf3 servers!!!\n\tYou can also use 'ps aguwx | grep iperf3' and kill process manually\n"
