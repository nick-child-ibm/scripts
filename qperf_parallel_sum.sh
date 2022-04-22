#!/bin/bash

# This scipt is used to find the sum bandwidth (or other value) from the output
# of a `parallel --jobs 32   --use_bits_per_sec -v -t 60 <qperf_server_ip> -lp {} tcp_bw ::: {1966..1997}` command. The output is something like:
# tcp_bw:
#     bw              =  1.97 Gb/sec
#     msg_rate        =  3.75 K/sec
#     time            =    60 sec
#     send_cost       =   5.9 sec/GB
#     recv_cost       =  6.65 sec/GB
#     send_cpus_used  =   145 % cpus
#     recv_cpus_used  =   163 % cpus
# tcp_bw:
#     bw              =  2.84 Gb/sec
#     msg_rate        =  5.41 K/sec
#     time            =    60 sec
#     send_cost       =  4.09 sec/GB
#     recv_cost       =  4.61 sec/GB
#     send_cpus_used  =   145 % cpus
#     recv_cpus_used  =   163 % cpus
# etc etc
# 
# So this script will sum over the values in bw and return the total bandwidth
# This is useful because net performance tools like iperf are single threaded
# qperf can run in different threads. But the output is per thread. We want
# the total

file=$1
metric="bw"
regex="${metric}([[:space:]]+)=([[:space:]]+)([0-9\.]+) ([GM])b/s"
thread=0
sum=0
while IFS= read -r line; do
    if [[ $line =~ $regex ]]
    then
        match="${BASH_REMATCH[3]}"
        echo "thread ${thread} = ${match}"   
        sum=$(bc -l <<<"${sum}+${match}")  
    	let "thread++"

    fi
done < $file
echo "Total is $sum"
