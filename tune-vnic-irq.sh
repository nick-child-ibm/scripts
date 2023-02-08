sleep 10
systemctl stop irqbalance
ethtool -L eth1 rx 16 tx 16
sleep 20

# eth1 RX
echo 0 > /proc/irq/38/smp_affinity_list
echo 4 > /proc/irq/39/smp_affinity_list
echo 8 > /proc/irq/40/smp_affinity_list
echo 12 > /proc/irq/41/smp_affinity_list
echo 16 > /proc/irq/42/smp_affinity_list
echo 20 > /proc/irq/43/smp_affinity_list
echo 24 > /proc/irq/44/smp_affinity_list
echo 28 > /proc/irq/45/smp_affinity_list
echo 32 > /proc/irq/46/smp_affinity_list
echo 36 > /proc/irq/47/smp_affinity_list
echo 40 > /proc/irq/48/smp_affinity_list
echo 44 > /proc/irq/49/smp_affinity_list
echo 48 > /proc/irq/50/smp_affinity_list
echo 52 > /proc/irq/51/smp_affinity_list
echo 56 > /proc/irq/52/smp_affinity_list
echo 60 > /proc/irq/53/smp_affinity_list

#eth1 TX
echo 2 > /proc/irq/22/smp_affinity_list
echo 6 > /proc/irq/23/smp_affinity_list
echo 10 > /proc/irq/24/smp_affinity_list
echo 14 > /proc/irq/25/smp_affinity_list
echo 18 > /proc/irq/26/smp_affinity_list
echo 22 > /proc/irq/27/smp_affinity_list
echo 26 > /proc/irq/28/smp_affinity_list
echo 30 > /proc/irq/29/smp_affinity_list
echo 34 > /proc/irq/30/smp_affinity_list
echo 38 > /proc/irq/31/smp_affinity_list
echo 42 > /proc/irq/32/smp_affinity_list
echo 46 > /proc/irq/33/smp_affinity_list
echo 50 > /proc/irq/34/smp_affinity_list
echo 54 > /proc/irq/35/smp_affinity_list
echo 58 > /proc/irq/36/smp_affinity_list
echo 62 > /proc/irq/37/smp_affinity_list
