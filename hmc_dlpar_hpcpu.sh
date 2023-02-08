#!/bin/bash

x=0;
testlpar=$1;
testmachine=$2
sleeptime=100;
rounds=15;
max_cpu=8;

#init to max
chhwres -m $testmachine -r proc -o a --procs 1 -p $testlpar -w 0
rc=$?
while [ $rc -eq 0 ]; do
	chhwres -m $testmachine -r proc -o a --procs 1 -p $testlpar -w 0
	rc=$?
done

while [ $x -le $rounds ]; do 
	echo "round $x";
	i=1
	while [ $i -lt $max_cpu ]; do
		echo "removing $i cpu's " $(date);
		chhwres -m $testmachine -r proc -o r --procs $i -p $testlpar -w 0 
		echo "done"; 
		sleep $sleeptime;
		echo "adding $i cpu " $(date); 
		chhwres -m $testmachine -r proc -o a --procs $i -p $testlpar -w 0
		echo "done." $(date); 
		sleep $sleeptime;
		((i=i+1));
	done;
	((x=x+1)); 
done
