#!/bin/bash

# this script will change the number of queues every interval and ensure that
# the number of new affinity is being set correctly

device=$1
max_tx_q=16
max_rx_q=16
interval=40
get_random_in_range () {
	echo `shuf -i 1-$1 -n 1`
}

for i in {1..100}
do
rx_q=$(get_random_in_range $max_rx_q)
tx_q=$(get_random_in_range $max_tx_q)
printf "Doing iteration : $i\nSetting rx to $rx_q and tx to $tx_q\n"
ethtool -L $device rx $rx_q tx $tx_q
rc=$?
if [ $rc -ne 0 ]; then
	echo "Could not set queues: rc = $rc"
	dmesg | tail -n 50
	exit $rc
fi
sleep 2
ethtool -l $device
./is_affinity_hint_respected.py $device
rc=$?
if [ $rc -ne 0 ]; then
        echo "Affinity check failed: rc = $rc"
	exit $rc
else
	printf "irq check passed!\n"
fi

sleep $interval
done


