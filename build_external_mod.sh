#!/bin/bash 
cd linux 
make -C /lib/modules/`uname -r`/build M=`pwd`/drivers/net/ethernet/ibm/ modules EXTRA_CFLAGS="-g -DDEBUG"
echo 8 > /proc/sys/kernel/printk
rmmod ibmveth
insmod ./drivers/net/ethernet/ibm/ibmveth.ko dyndbg==p
