#!/bin/bash
# Run this script as: ./<script_name> <interface name>
interface=$1
#ethtool -L ${interface} rx 16 tx 16
drc=$(ofpathname ${interface} | awk -F@ '{print $2}')
irqs=$(cat /proc/interrupts | grep ${drc} | awk -F":" '{print $1}')

for a in $irqs
do
    cat /proc/interrupts |  grep $drc | grep "${a}:"  | rev | cut -d ' ' -f 1 | rev | xargs echo "IRQ : $a -> "
    grep -r /proc/irq/${a}/ -e '.'
done
