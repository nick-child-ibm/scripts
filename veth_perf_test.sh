#!/bin/bash

HCALL_DIR=/root/nchild/linux/tools/perf
dev=$1
peer_dev=$2
ip=$3
peer_ip=$4
peer_pub=$5

# assumes 64 procs on both, 16 tx queues on devices
log_dir=veth_test_results/$(date +"%Y_%m_%d_%I_%M_%p")

mkdir -p $log_dir

run_iperf () {
    # $1 == output file
    (ssh $peer_pub -C "iperf -s > /dev/null "&)
    sleep 3
    iperf -c $peer_ip -B $ip -P 4 -l 5M -i 3 > $1
    pkill iperf
    ssh $peer_pub -C "pkill iperf"
}

iperf_iterations () {
    # $1 == test_name
    # $2 == num_iterations
    mkdir -p $log_dir/$1
    i=1
    while [ $i -le $2 ]; do
        run_iperf $log_dir/$1/${i}_iperf.txt
        sleep 1
        ((i=i+1))
    done
}

xps_read () {
    echo "XPS on host:"
    grep -r /sys/class/net/${dev}/queues/tx-*/xps_cpus -e '.' | sort -t- -k2,2n
    echo "XPS on peer:"
    ssh $peer_pub -C "grep -r /sys/class/net/${peer_dev}/queues/tx-*/xps_cpus -e '.' | sort -t- -k2,2n"
}

xps_on_all () {
    echo "turning on xps to all cpus on both peer and host"
    for i in {0..15}; do
        echo ffffffff,ffffffff > /sys/class/net/${dev}/queues/tx-${i}/xps_cpus
        ssh $peer_pub -C "echo ffffffff,ffffffff > /sys/class/net/${peer_dev}/queues/tx-${i}/xps_cpus" ; 
    done 
    xps_read
}

xps_off () {
    echo "turning off xps on peer and host"
    for i in {0..15}; do
        echo 00000000,00000000 > /sys/class/net/${dev}/queues/tx-${i}/xps_cpus
        ssh $peer_pub -C "echo 00000000,00000000 > /sys/class/net/${peer_dev}/queues/tx-${i}/xps_cpus" ;
    done
    xps_read
}

xps_distributed () {
    echo "turning xps on distributed cpu's on peer and host"
    # 64 procs, 16 tx queues = every queue gets 4 cpu (ie f)
    map="f"
    for i in {0..15}; do
        if [ $i -gt 7 ]; then
            echo $map,0 > /sys/class/net/${dev}/queues/tx-${i}/xps_cpus
            ssh $peer_pub -C "echo $map,0 > /sys/class/net/${peer_dev}/queues/tx-${i}/xps_cpus" ;
        else
            echo $map > /sys/class/net/${dev}/queues/tx-${i}/xps_cpus
            ssh $peer_pub -C "echo $map > /sys/class/net/${peer_dev}/queues/tx-${i}/xps_cpus" ;
        fi
        map="${map}0"
        if [ $i -eq 7 ]; then
            map="f"
        fi
    done
    xps_read
}

rps_read () {
    echo "RPS on host:"
    cat /sys/class/net/$dev/queues/rx-0/rps_cpus
    echo "RPS on peer:"
    ssh $peer_pub -C "cat /sys/class/net/$peer_dev/queues/rx-0/rps_cpus"
}

rps_on_all () {
    echo "turning rps on all cpus' on peer and host"
    echo ffffffff,ffffffff > /sys/class/net/$dev/queues/rx-0/rps_cpus
    ssh $peer_pub -C "echo ffffffff,ffffffff > /sys/class/net/$peer_dev/queues/rx-0/rps_cpus"
    rps_read
}

rps_off () {
    echo "turning rps off for peer and host"
    echo 00000000,00000000 > /sys/class/net/$dev/queues/rx-0/rps_cpus
    ssh $peer_pub -C "echo 00000000,00000000 > /sys/class/net/$peer_dev/queues/rx-0/rps_cpus"
    rps_read
}

rfs_read () { 
    echo "RFS on host:"
    cat /sys/class/net/$dev/queues/rx-0/rps_flow_cnt
    cat /proc/sys/net/core/rps_sock_flow_entries
    echo "RFS on peer:"
    ssh $peer_pub -C "cat /sys/class/net/$peer_dev/queues/rx-0/rps_flow_cnt"
    ssh $peer_pub -C "cat /proc/sys/net/core/rps_sock_flow_entries"
}

rfs_on () {
    echo "turning RFS on for peer and host (flow_cnt = 32768)"
    echo 32768 > /sys/class/net/$dev/queues/rx-0/rps_flow_cnt
    echo 32768 > /proc/sys/net/core/rps_sock_flow_entries
    ssh $peer_pub -C "echo 32768 > /sys/class/net/$peer_dev/queues/rx-0/rps_flow_cnt"
    ssh $peer_pub -C "echo 32768 > /proc/sys/net/core/rps_sock_flow_entries"
    rfs_read
}


rfs_off () {
    echo "setting RFS off for host and peer"
    echo 0 > /sys/class/net/$dev/queues/rx-0/rps_flow_cnt
    echo 0 > /proc/sys/net/core/rps_sock_flow_entries
    ssh $peer_pub -C "echo 0 > /sys/class/net/$peer_dev/queues/rx-0/rps_flow_cnt"
    ssh $peer_pub -C "echo 0 > /proc/sys/net/core/rps_sock_flow_entries"
    rfs_read
}

rfs_off
rps_off
xps_off
iperf_iterations all_off 10
rps_on_all
iperf_iterations rps_all 10
xps_on_all
iperf_iterations rps_all_xps_all 10
xps_off
xps_distributed
iperf_iterations rps_all_xps_dist 10
rps_off
xps_off
rfs_on
iperf_iterations rfs 10
rfs_off
xps_on_all
iperf_iterations xps_all 10
rfs_on
iperf_iterations rfs_xps_all 10
xps_distributed
iperf_iterations rfs_xps_dist 10
rfs_off
xps_off
xps_distributed
iperf_iterations xps_dist 10
xps_off
rps_off
rfs_off
