#!/bin/bash 
# Run this script as: ./<script name> <interface name> 
if [ $# -lt 1 ]; then
    echo "USAGE: $0 <dev>" 1>&2;
    exit 1
fi


interface=$1;
drc=$(ofpathname ${interface} | awk -F@ '{print $2}');
max_cpu=$((`nproc`<64 ? `nproc` : 64))
rxs=($(cat /proc/interrupts | grep ${drc} | grep rx | awk -F":" '{print $1}'));
txs=($(cat /proc/interrupts | grep ${drc} | grep tx | awk -F":" '{print $1}'));
total_irqs=$(cat /proc/interrupts | grep ${drc}- | wc -l);
cpu_per_irq=$((max_cpu/total_irqs));

rfs_entries=32768

if [ $cpu_per_irq -eq 0 ]; then
    stragglers=$total_irqs;
else
    stragglers=$((max_cpu%total_irqs));
fi
cpu=0; 
i=0;
while [ $i -lt $total_irqs ]; do
    if [ $((i/2)) -ge ${#txs[@]} ]; then
         q="rx-$((i-${#txs[@]}))";
         irq=${rxs[$i-${#txs[@]}]};
    elif [ $((i/2)) -ge ${#rxs[@]} ]; then
        q="tx-$((i-${#rxs[@]}))";
        irq=${txs[$i-${#rxs[@]}]};
    elif [ $((i%2)) -eq 0 ]; then
        q="tx-$((i/2))";
        irq=${txs[$i/2]};
    else
        q="rx-$((i/2))";
        irq=${rxs[$i/2]};
    fi

    # 1. set affinity value (cpu's that handle this irq)
    if [ $stragglers -gt 0 ]; then
        echo $cpu-$((cpu+cpu_per_irq)) > /proc/irq/${irq}/smp_affinity_list;
        ((cpu=(cpu+cpu_per_irq+1)%max_cpu));
        ((stragglers=stragglers-1));
    else
        echo $cpu-$((cpu+cpu_per_irq-1)) > /proc/irq/${irq}/smp_affinity_list;
        ((cpu=cpu+cpu_per_irq));
    fi

    # 2. Enable RPS/XPS on same set of cpu's as 1.
    if [[ $q =~ 'rx' ]]; then
        cat /proc/irq/${irq}/smp_affinity > /sys/class/net/${interface}/queues/${q}/rps_cpus
        # 3. Enable RFS
        echo $((rfs_entries/${#rxs[@]})) > /sys/class/net/${interface}/queues/${q}/rps_flow_cnt;
    else
        cat /proc/irq/${irq}/smp_affinity > /sys/class/net/${interface}/queues/${q}/xps_cpus
    fi


    ((i=i+1));
done

    # 4. Final step for RFS enablement
    echo $rfs_entries > /proc/sys/net/core/rps_sock_flow_entries
