#!/bin/sh

if [ $# -ne 4 ]; then
        echo -e "\nPlease use '$0 <Server IP> <Exec Time> <nConnections>' to run this command!\n"
        exit 1
fi

SERVER_IP=$1
EXEC_TIME=$2

echo "Server IP: " $SERVER_IP  "Exec time:" $EXEC_TIME "seconds for each test case"

TEST_CASE="tcp_rr"
TEST_RESULT_NAME=$TEST_CASE".result"
BIN=netperf

for cnt in $3
do
        echo
        echo $cnt "netperf streams running ..."
        echo > $TEST_RESULT_NAME$cnt

        for ((i=1; i <= $cnt; i++)); do
                $BIN -H $SERVER_IP -l $EXEC_TIME -t $TEST_CASE -- -D  -r $4 >> $TEST_RESULT_NAME$cnt &
        done
        wait

        echo "Write result to" $TEST_RESULT_NAME$cnt
        cat $TEST_RESULT_NAME$cnt | grep " $2\.0. " | awk '{print $6}' | awk '{sum+=$1} END {print "Netperf stream number =", NR, ", sum =", sum} '
done
