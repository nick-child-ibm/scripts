#!/bin/bash
# https://wiki.linuxfoundation.org/networking/bonding
devices=("env2" "env4" "env5" "env6")
bond_device="bond4"
bond_ip="ADD NEW IP HERE"
ip link

function remove_bond_interface(  ) {
	echo "REMOVING ${bond_device}"
	echo \> ip link delete dev ${bond_device}
	ip link delete dev ${bond_device}
	echo \> "echo -${bond_device} > /sys/class/net/bonding_masters"
	echo -${bond_device} > /sys/class/net/bonding_masters
}
if [ "$1" == "remove" ] ; then
	remove_bond_interface
	exit 0
fi

for d in ${devices[@]}; do
	echo \> "echo ip addr flush dev $d"
	echo ip addr flush dev $d
done

for d in ${devices[@]}; do
	echo \> "ip link set $d down"
	ip link set $d down
done

echo \> "modprobe bonding"
modprobe bonding
echo \> "echo +${bond_device} > /sys/class/net/bonding_masters"
echo +${bond_device} > /sys/class/net/bonding_masters

# balance rr
echo \> "echo 0  > /sys/class/net/bond4/bonding/mode"
echo 0  > /sys/class/net/bond4/bonding/mode

echo \> "echo 100 > /sys/class/net/bond4/bonding/miimon"
echo 100 > /sys/class/net/bond4/bonding/miimon

for d in ${devices[@]}; do
	echo \> "echo +${d} > /sys/class/net/bond4/bonding/slaves"
	echo +${d} > /sys/class/net/bond4/bonding/slaves
done

for d in ${devices[@]}; do
	echo \> "ip link set $d up"
	ip link set $d up
done

echo \> "ip addr add $bond_ip dev $bond_device"
ip addr add $bond_ip dev $bond_device
echo \> "ip link set $bond_device up"
ip link set $bond_device up

echo \> cat /proc/net/bonding/${bond_device}
cat /proc/net/bonding/${bond_device}