#!/bin/bash

if [ $# -lt 1 ]; then
    printf "USAGE: $0 <name of netdev>\n"
    exit 1
fi
dev=$1

# stores [rx_packets, rx_bytes]
ethtool_rx_stats=(`ethtool -S ${dev} | grep  -e " rx_packets\|rx_bytes" | cut -d':' -f2 | awk 'BEGIN {ORS = " "} {print $1, $2}'`);
ethtool_tx_stats=(`ethtool -S ${dev} | grep  -e " tx_packets\|tx_bytes" | cut -d':' -f2 | awk 'BEGIN {ORS = " "} {print $1, $2}'`);
ifconfig &> /dev/null
if [ $? -eq 0 ]; then
    ifconfig_rx_stats=(`ifconfig ${dev} | grep -i "RX packets" | awk '{print $3, $5}'`);
    ifconfig_tx_stats=(`ifconfig ${dev} | grep -i "TX packets" | awk '{print $3, $5}'`);

else
    ifconfig_rx_stats=(`grep /sys/class/net/${dev}/statistics/* -e ".*" |  grep -e "\s*rx_bytes\|rx_packets" | cut -d":" -f2- | xargs | awk -F' ' '{print $2, $1}'`)
    ifconfig_tx_stats=(`grep /sys/class/net/${dev}/statistics/* -e ".*" |  grep -e "\s*tx_bytes\|tx_packets" | cut -d":" -f2- | xargs | awk -F' ' '{print $2, $1}'`)

fi

printf "ethtool rx:  ${ethtool_rx_stats[0]} pkts\t${ethtool_rx_stats[1]} b\n";
printf "ifconfig rx: ${ifconfig_rx_stats[0]} pkts\t${ifconfig_rx_stats[1]} b\n";
printf "%%_diff:      %0.4f%%\t%0.4f%%\n" `echo "scale=3; 100*${ethtool_rx_stats[0]}/${ifconfig_rx_stats[0]}" | bc -l` `echo "scale=3; 100*${ethtool_rx_stats[1]}/${ifconfig_rx_stats[1]}" | bc -l`
printf "\n"
printf "ethtool tx:  ${ethtool_tx_stats[0]} pkts\t${ethtool_tx_stats[1]} b\n";
printf "ifconfig tx: ${ifconfig_tx_stats[0]} pkts\t${ifconfig_tx_stats[1]} b\n";
printf "%%_diff:      %0.4f%%\t%0.4f%%\n" `echo "scale=3; 100*${ethtool_tx_stats[0]}/${ifconfig_tx_stats[0]}" | bc -l` `echo "scale=3; 100*${ethtool_tx_stats[1]}/${ifconfig_tx_stats[1]}" | bc -l`
