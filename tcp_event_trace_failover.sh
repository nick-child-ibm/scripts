#!/bin/bash

device=$(ofpathname env5  |  awk -F@ '{print $2}')

ftrace=/sys/kernel/debug/tracing

cd $ftrace
echo 1 > tracing_on
echo > trace
echo > set_ftrace_filter
echo nop > current_tracer
# clearing trace_pipe
echo 0 > /sys/kernel/debug/tracing/events/tcp/enable;
(cat /sys/kernel/debug/tracing/trace_pipe > /dev/null &);
sleep 1;
ps aguwx | grep trace_pipe | grep sys | awk '{print $2}' |  xargs kill ;

echo 1 > /sys/kernel/debug/tracing/events/tcp/enable;
sleep 2
#run failover
printf "Running failover\n"
echo 1 > /sys/devices/vio/${device}/failover
# wait for failover to complete
dmesg | grep "Done processing resets" > /dev/null;

while [ $? -eq 1 ];do 
	printf "failover in progress\n";
	sleep 0.01;
	dmesg | grep "Done processing resets" > /dev/null;
done

printf "failover complete\n"


# wait for us to get back to cong_state 0 for 2 whole sends
printf "waiting for cong state 0\n"
rc=1
while [ $rc -eq 1 ];do

	cat trace | grep "cong_state=0" > /dev/null;
	while [ $? -eq 1 ];do 
		sleep 0.1
		cat trace | grep "cong_state=0" > /dev/null;
	done
	printf "cong state recoverd\n"
	# make sure we are in stte 0 for 2 seconds and it is most recent state
	sleep 2;
	cat trace | grep "cong_state" | tail -n 1 | grep "cong_state=0" > /dev/null;
	rc=$?
done
printf "cong state confirmed\n"

# turn off tracing
echo 0 > /sys/kernel/debug/tracing/events/tcp/enable;
echo 0 > tracing_on

# capture just congestion state changes and 2 and one digit ssthresh
cat trace | grep "cwnd=. \|ssthresh=.. \|ssthresh=. \| cong_state" -A 2 -B 1
