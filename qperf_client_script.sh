#!/bin/bash


out_dir=$1
ip_addr=$2
rounds=4

i=0
while [ $i -lt $rounds ]; do
    echo "running round $i"
    ./qperf_client.sh $ip_addr 4 5M
    mkdir -p ./$out_dir/$i
    mv /tmp/qprf_* ./$out_dir/$i/
    i=$((i+1));
    sleep 1
done

grep ./$out_dir/*/* -e "bw\s" | awk '{ print $4 }' | xargs python -c "import sys; floats  = [float(i) for i in (sys.argv[1:])]; print(f'AVG is: {sum(floats)/$rounds}')"

