#!/bin/bash

device=$(ofpathname env5  |  awk -F@ '{print $2}')

ftrace=/sys/kernel/debug/tracing

cd $ftrace
echo 0 > tracing_on
echo > trace 
echo > set_ftrace_filter
echo nop > current_tracer 
echo 1 > options/graph-time

echo '*ibmvnic*' > set_ftrace_filter
echo '*tcp*' >> set_ftrace_filter


# turn tracing on
echo 1 > function_profile_enabled
#run failover
printf "Running failover\n"
echo 1 > /sys/devices/vio/$device/failover
# wait for failover to complete
dmesg | grep "Done processing resets";

while [ $? -eq 1 ];do 
	printf "failover in progress\n";
	sleep 0.01;
	dmesg | grep "Done processing resets";
done

printf "failover complete\n"
sleep 0.2

# turn off tracing
echo 0 > function_profile_enabled
cat trace_stat/function*

dmesg -C
