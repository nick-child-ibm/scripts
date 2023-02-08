#!/bin/bash
if [[ $# -lt 4 ]]; then
    printf "USAGE: $0 <local_vnic_dev> <peer_public_ip> <peer_private_ip> <peer_vnic_dev>\nThis script captures the bahaviour of mtu changes, pcaps are available on host and peer at /tmp/host.pcap and /tmp/peer.pcap respectively\n"
    exit 1;
fi

dev=$1
peer_pub=$2
peer_priv=$3
peer_dev=$4

echo "Setting local $dev to 9000"
ip l s mtu 9000 dev $dev
ip a
echo "setting peer $peer_dev to 9000"
ssh $peer_priv "ip l s mtu 9000 dev $peer_dev"


echo "setting local $dev to 1500"
ip l s mtu 1500 $dev
ip a

echo "starting remote tcp"
ssh $peer_pub "tcpdump -i $peer_dev -w /tmp/peer.pcap "&
echo "starting local tcp"
tcpdump -i $dev -w /tmp/host.pcap &
sleep 2

echo "setting peer $peer_dev to 1500"
ssh $peer_priv "ip l s mtu 1500 dev $peer_dev"
echo "killing things"
pkill tcpdump
ssh $peer_pub 'pkill tcpdump'
echo "DONE! pcaps are at /tmp/host.pcap & $peer_pub:/tmp/peer.pcap"
