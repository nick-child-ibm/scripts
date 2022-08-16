#!/bin/bash

device=bond1

for i in {1..100}
do
printf "Doing iteration : $i\nSetting mtu 9000\n"
ip l set mtu 9000 $device
sleep 60
printf "setting back to 1500\n"
ip l set mtu 1500 $device
sleep 60
done


