#!/bin/bash

if [ $# -lt 1 ]; then
    printf "USAGE: $0 <name of netdev>\n"
    exit 1
fi
dev=$1

# stores [rx_packets, rx_bytes]
ethtool_rx_stats=(`ethtool -S ${dev} | grep  -e " rx_packets\|rx_bytes" | cut -d':' -f2 | awk 'BEGIN {ORS = " "} {print $1, $2}'`);
ifconfig_rx_stats=(`ifconfig $env9 | grep "RX packets" | awk '{print $3, $5}'`);
printf "ethtool rx:  ${ethtool_rx_stats[0]} pkts\t${ethtool_rx_stats[1]} b\n";
printf "ifconfig rx: ${ifconfig_rx_stats[0]} pkts\t${ifconfig_rx_stats[1]} b\n";
printf "%%_diff:      %0.4f%%\t%0.4f%%\n" `echo "scale=3; 100*${ethtool_rx_stats[0]}/${ifconfig_rx_stats[0]}" | bc -l` `echo "scale=3; 100*${ethtool_rx_stats[1]}/${ifconfig_rx_stats[1]}" | bc -l`
