#!/bin/bash

host_public_ip=9.XX.XX.XX
host_user=root
host_pwd=XXXX

peer_public_ip=9.XX.XX.XX
peer_user=root
peer_pwd=XXXX

hmc_ip=vhmc15.aus.stglabs.ibm.com
hmc_user=hscroot
hmc_pwd=XXXX

host_ip_1=101.XX.XX.XX
host_dev_1=bondXXXXX

host_ip_2=102.XX.XX.XX
host_dev_2=bondXXXXXX

peer_ip_1=101.XX.XX.XX
peer_dev_1=bondXXXXXX

peer_ip_2=102.XX.XX.XX
peer_dev_2=bondXXXXXX

lpar_to_lpm=XXXXX
cec_2=XXXX
cec_1=XXXX

iperf=iperf
iperf_log_file="/tmp/iperf_log"
tcpdump_log_dir="/root/nchild/tcpdump/"

# yes this is a global variable soooo dont override in scripts
most_recent_command_output=
# run_cmd <user> <ip> <password> <command>
run_cmd () {
        cmd="sshpass -p "$3" ssh -o StrictHostKeyChecking=no $1@$2 ${@:4}"
        most_recent_command_output=`$cmd`
        return $?
}

# run_host_cmd "<cmd>"
run_host_cmd () {
        echo "HOST running: $@"
        run_cmd $host_user $host_public_ip $host_pwd $@
        return $?
}

run_peer_cmd () {
        echo "PEER running: $@"
        run_cmd $peer_user $peer_public_ip $peer_pwd $@
        return $?
}

run_hmc_cmd () {
        echo "HMC running: $@"
        run_cmd $hmc_user $hmc_ip $hmc_pwd $@
        return $?
}

kill_tcpdump () {
        run_host_cmd "pkill tcpdump"
        run_peer_cmd "pkill tcpdump"
}

start_tcpdump() {
        run_host_cmd "netstat -ntap | grep -oP \"(?<=${host_ip_1}:)\w* \" | sort | uniq"
        host_ports=$most_recent_command_output
        for $p in $host_ports; do
                run_host_cmd "tcpdump -i $host_dev_1 -C 250 -W 4 -w ${tcpdump_log_dir}/${host_dev_1}_w_${peer_ip_1}_${p}.pcap -Z root -S port $p" &
        done
       
        run_host_cmd "netstat -ntap | grep -oP \"(?<=${host_ip_2}:)\w* \" | sort | uniq"
        host_ports=$most_recent_command_output
        for $p in $host_ports; do
                run_host_cmd "tcpdump -i $host_dev_2 -C 250 -W 4 -w ${tcpdump_log_dir}/${host_dev_2}_w_${peer_ip_2}_${p}.pcap -Z root -S port $p" &
        done

        run_peer_cmd "netstat -ntap | grep -oP \"(?<=${peer_ip_1}:)\w* \" | sort | uniq"
        peer_ports=$most_recent_command_output
        for $p in $peer_ports; do
                run_peer_cmd "tcpdump -i $peer_dev_1 -C 250 -W 4 -w ${tcpdump_log_dir}/${peer_dev_1}_w_${host_ip_1}_${p}.pcap -Z root -S port $p" &
        done
       
        run_peer_cmd "netstat -ntap | grep -oP \"(?<=${peer_ip_2}:)\w* \" | sort | uniq"
        peer_ports=$most_recent_command_output
        for $p in $peer_ports; do
                run_host_cmd "tcpdump -i $peer_dev_2 -C 250 -W 4 -w ${tcpdump_log_dir}/${peer_dev_2}_w_${peer_ip_2}_${p}.pcap -Z root -S port $p" &
        done
}

make_sure_tcpdump_is_running () {
        run_host_cmd "ps aux | grep 'tcpdump' | grep -v 'grep' | wc -l"
        rc_host=$?
        if [ $most_recent_command_output -ne 2 ]; then
                printf "tcpdump not running on host\n"
                rc_host=1
        fi
        run_peer_cmd "ps aux | grep 'tcpdump' | grep -v 'grep' | wc -l"
        rc_peer=$?
        if [ $most_recent_command_output -ne 2 ]; then
                printf "tcpdump not running on peer\n"
                rc_peer=1
        fi

        return $(($rc_peer + $rc_host))
}



start_iperf () {
        # start iperf with client as server
        server_cmd="$iperf -s &"

        client_cmd="$iperf -c $peer_ip_1 -B $host_ip_1 -P 4 -l 5M -t0 -i 5 > ${iperf_log_file}_${peer_ip_1} "
        run_peer_cmd $server_cmd &
        sleep 1
        run_host_cmd $client_cmd &

        # start iperf with peer as server
        client_cmd="$iperf -c $host_ip_2 -B $peer_ip_2 -P 4 -l 5M -t0 -i 5 > ${iperf_log_file}_${host_ip_2} "
        run_host_cmd $server_cmd &
        sleep 1
        run_peer_cmd $client_cmd &
}

make_sure_iperf_is_running () {
        run_host_cmd "ps aux | grep 'iperf -c' | grep -v 'grep'"
        rc_host=$?
        if [ $rc_host -ne 0 ]; then
                printf "iperf client is not running on host\n"
        else
                run_host_cmd "ps aux | grep 'iperf -s' | grep -v 'grep'"
                rc_host=$?
                if [ $rc_host -ne 0 ]; then
                        printf "iperf server is not running on host\n"
                fi
        fi
        run_peer_cmd "ps aux | grep 'iperf -s' | grep -v 'grep'"
        rc_peer=$?
        if [ $rc_peer -ne 0 ]; then
                printf "iperf server is not running on peer\n"
        else
                run_peer_cmd "ps aux | grep 'iperf -c' | grep -v 'grep'"
                rc_peer=$?
                if [ $rc_peer -ne 0 ]; then
                        printf "iperf client is not running on peer\n"
                fi   
        fi

        return $(($rc_peer + $rc_host))
}

check_iperf_bw_drop () {
        # check if connection on iperf dropped to bits/sec range
        echo "Checking iperf bw"
        run_host_cmd "date"
        echo "$most_recent_command_output"
        run_host_cmd "tail $iperf_log_file* | grep -e 'SUM.* bits/sec'"
        rc=$?
        if [ $rc -eq 0 ]; then
                printf "iperf bandwidth dropped after failover\n iperf_log:\n"
                run_host_cmd "cat ${iperf_log_file}"
                echo "$most_recent_command_output"
                return -1
        fi
        run_peer_cmd "date"
        echo "$most_recent_command_output"
        run_peer_cmd "tail $iperf_log_file* | grep -e 'SUM.* bits/sec'"
        rc=$?
        if [ $rc -eq 0 ]; then
                printf "iperf bandwidth dropped after failover\n iperf_log:\n"
                run_host_cmd "cat ${iperf_log_file}"
                echo "$most_recent_command_output"
                return -1
        fi
        echo "bw good"
        return 0
}

start_tracing () {
        # run_peer_cmd "echo 1 > /sys/kernel/debug/tracing/events/tcp/tcp_probe/enable"
        # run_peer_cmd "echo 1 > /sys/kernel/debug/tracing/events/tcp/tcp_cong_state_set/enable"
        run_peer_cmd "echo 1 > /sys/kernel/debug/tracing/events/tcp/enable"
        run_peer_cmd "echo 1 > /sys/kernel/debug/tracing/tracing_on"

        # run_host_cmd "echo 1 > /sys/kernel/debug/tracing/events/tcp/tcp_probe/enable"
        # run_host_cmd "echo 1 > /sys/kernel/debug/tracing/events/tcp/tcp_cong_state_set/enable"
        run_host_cmd "echo 1 > /sys/kernel/debug/tracing/events/tcp/enable"
        run_host_cmd "echo 1 > /sys/kernel/debug/tracing/tracing_on"
}

stop_tracing () {
        run_host_cmd "echo 0 > /sys/kernel/debug/tracing/tracing_on"
        run_peer_cmd "echo 0 > /sys/kernel/debug/tracing/tracing_on"
}

cleanup () {       
        #run_host_cmd "pkill -9 iperf"
        #run_peer_cmd "pkill -9 iperf"
        kill_tcpdump
        stop_tracing
        sleep 3
}

check_htx_errs () {
        run_peer_cmd "hcl -query | grep $peer_dev_1 | awk '{print \$NF}'"
        if [ $most_recent_command_output -ne 0 ]; then 
                return 1
        fi;

        run_peer_cmd "hcl -query | grep $peer_dev_2 | awk '{print \$NF}'"
        if [ $most_recent_command_output -ne 0 ]; then 
                return 1
        fi;

        run_host_cmd "hcl -query | grep $host_dev_1 | awk '{print \$NF}'"
        if [ $most_recent_command_output -ne 0 ]; then 
                return 1
        fi;

        run_host_cmd "hcl -query | grep $host_dev_2 | awk '{print \$NF}'"
        if [ $most_recent_command_output -ne 0 ]; then 
                return 1
        fi;

        return 0;
}

handler () {
        printf "\nCLEANING UP BEFORE EXITING!\n"
        cleanup
        exit 0
}

trap handler SIGINT

printf "Cleaning any existing process\n"
cleanup
#run_host_cmd "rm $iperf_log_file*"
#run_peer_cmd "rm $iperf_log_file*"
run_peer_cmd "mkdir $tcpdump_log_dir"
run_host_cmd "mkdir $tcpdump_log_dir"

#start_iperf
start_tcpdump
start_tracing

i=0;
while true; do
        sleep 5;

        #make_sure_iperf_is_running
        # rc=$?
        # if [ $rc -ne 0 ]; then
        #         printf "iperf is not running on host/peer\n iperf_log:\n"
        #         run_host_cmd "cat ${iperf_log_file}*"
        #         echo "$most_recent_command_output"
        #         cleanup
        #         exit $rc
        # fi

        make_sure_tcpdump_is_running
        rc=$?
        if [ $rc -ne 0 ]; then
                printf "tcpdump is not running on host/peer\n"
                cleanup
                exit $rc
        fi

        printf "Doing iteration : $i\nStarting LPM of $lpar_to_lpm to $cec_1\n"
        run_hmc_cmd "migrlpar -o m -t $cec_1 -m $cec_2 -p $lpar_to_lpm"
        rc=$?
        if [ $rc -ne 0 ]; then
                echo "running LPM failed"
                echo "$most_recent_command_output"
                cleanup
                exit $rc
        fi
        echo "migration done"

        sleep 2
        j=0
        while [ $j -lt 9 ]; do 
                check_htx_errs
                rc=$?
                if [ $rc -ne 0 ]; then
                        echo "HTX ERR DETECTED!!!!!"
                        stop_tracing
                        kill_tcpdump
                        exit $rc
                fi
                sleep 10
                ((j=j+1))
        done

        check_htx_errs
        rc=$?
        if [ $rc -ne 0 ]; then
                echo "HTX ERR DETECTED!!!!!"
                stop_tracing
                kill_tcpdump
                exit $rc
        fi

        printf "Doing iteration : $i\nStarting LPM of $lpar_to_lpm to $cec_2\n"
        run_hmc_cmd "migrlpar -o m -t $cec_2 -m $cec_1 -p $lpar_to_lpm"
        rc=$?
        if [ $rc -ne 0 ]; then
                echo "running LPM failed"
                echo "$most_recent_command_output"
                cleanup
                exit $rc
        fi
        echo "migration done"

        # check_iperf_bw_drop
        # rc=$?
        # if [ $rc -ne 0 ]; then
        #         kill_tcpdump
        #         echo "BW DROP DETECTED!!!!!"
        #         exit $rc
        # fi

        sleep 2
        j=0
        while [ $j -lt 9 ]; do 
                check_htx_errs
                rc=$?
                if [ $rc -ne 0 ]; then
                        echo "HTX ERR DETECTED!!!!!"
                        stop_tracing
                        kill_tcpdump
                        exit $rc
                fi
                sleep 10
                ((j=j+1))
        done

        check_htx_errs
        rc=$?
        if [ $rc -ne 0 ]; then
                echo "HTX ERR DETECTED!!!!!"
                stop_tracing
                kill_tcpdump
                exit $rc
        fi
        printf "\n\n"

        ((i=i+1))
done


cleanup
