#!/bin/bash

# This script runs drops a percentage of packets for a defined number of
# seconds while iperf3 is running. Tcpfump and tcp engine traces are also
# logged to a file
# By Nick Child

# if you end this script early make sure to run:
# ps aguwx | grep iperf | grep -v grep | awk '{print $2}' |  xargs kill
# ps aguwx | grep trace_pipe | grep sys | awk '{print $2}' |  xargs kill
# echo 0 > /sys/kernel/debug/tracing/events/tcp/enable
# ps aguwx | grep tcpdump | grep -v grep | awk '{print $2}' |  xargs kill ;

THIS_DIR=`readlink -f $(dirname "$0")`
TIME=$(date -d "today" +"%Y%m%d%H%M")
LOGS_DIR=logs
outfile=${THIS_DIR}/${LOGS_DIR}/${TIME}
x=0; r=0;
serverIP=100.64.0.142 ;
bindIP=100.64.0.141 ; dev=eth2 ;
runTime=300; dropTime=10; rounds=20; roundsOfRounds=1;


let totalTime=(runTime+dropTime)*rounds;
printf "output is in ${THIS_DIR}/${LOGS_DIR}/${TIME}-*\n"
echo > ${outfile}-iperf.txt;
# for tcpdump results # echo > ${outfile}-tcpdump.txt;
echo > ${outfile}-trace_tcp.txt;

# clearing trace_pipe
echo 0 > /sys/kernel/debug/tracing/events/tcp/enable;
(cat /sys/kernel/debug/tracing/trace_pipe > /dev/null &);
sleep 1;
ps aguwx | grep trace_pipe | grep sys | awk '{print $2}' |  xargs kill ;

# start logging tcp trace and dumps
(grep "${bindIP}" /sys/kernel/debug/tracing/trace_pipe >>  ${outfile}-trace_tcp.txt &);
# for tcpdump results # (tcpdump -i $dev  &>> ${outfile}-tcpdump.txt &);
while [ $r -lt $roundsOfRounds ]; do
	printf "Round $r is starting, to quit, stop the script and run: \n\tps aguwx | grep iperf | grep -v grep | awk '{print \$2}' |  xargs kill;\n\tps aguwx | grep trace_pipe | grep sys | awk '{print \$2}' |  xargs kill;\n\tps aguwx | grep tcpdump | grep -v grep | awk '{print \$2}' |  xargs kill;\n\techo 0 > /sys/kernel/debug/tracing/events/tcp/enable;\n"
	# start a new iperf connection
	printf "`date +%T` Running iperf3 round $r \n" >> ${outfile}-iperf.txt;
	# for tcpdump results # printf "`date +%T` Running iperf3 round $r \n" >> ${outfile}-tcpdump.txt;
	printf "`date +%T` Running iperf3 round $r \n" >> ${outfile}-trace_tcp.txt;
	(iperf3 -B $bindIP -c $serverIP -i 30 -t $totalTime --logfile ${outfile}-iperf.txt &);
	
	while [ $x -lt $rounds ]; do
		# while iperf is running do this chunk
		printf "`date +%T` Round $x\n" >> ${outfile}-iperf.txt;
		# for tcpdump results # printf "`date +%T` Round $x\n" >> ${outfile}-tcpdump.txt;
		printf "\n`date +%T` Round $x\n" >> ${outfile}-trace_tcp.txt;
		sleep $(($runTime - 8)); 
		printf "\n`date +%T` Enabling tracing \n" >> ${outfile}-trace_tcp.txt;
		echo 1 > /sys/kernel/debug/tracing/events/tcp/enable;
		sleep 2;
		printf  "`date +%T` dropping 100%% of packets \n" >> ${outfile}-iperf.txt;
		# for tcpdump results # printf  "`date +%T` dropping 100%% of packets \n" >> ${outfile}-tcpdump.txt;
		printf  "`date +%T` dropping 100%% of packets \n" >> ${outfile}-trace_tcp.txt;
		tc qdisc add dev $dev root netem loss 100%;
		sleep $dropTime;
		tc qdisc del dev $dev root netem loss 100% ;
		printf  "`date +%T` Removing 100%% drop rule \n" >> ${outfile}-iperf.txt;
		# for tcpdump results # printf  "`date +%T` Removing 100%% drop rule \n" >> ${outfile}-tcpdump.txt;
		printf  "\n`date +%T` Removing 100%% drop rule \n" >> ${outfile}-trace_tcp.txt;
		sleep 6;
		echo 0 > /sys/kernel/debug/tracing/events/tcp/enable;
		printf "\n`date +%T` Disabled tracing \n" >> ${outfile}-trace_tcp.txt;
		((x=x+1));
	done;
	((r=r+1));
	x=0;

	sleep 600;
done ;
ps aguwx | grep trace_pipe | grep sys | awk '{print $2}' |  xargs kill ;
ps aguwx | grep iperf | grep -v grep | awk '{print $2}' |  xargs kill ;
ps aguwx | grep tcpdump | grep -v grep | awk '{print $2}' |  xargs kill ;