#!/bin/bash


host_public_ip=XXXX
host_user=root
host_pwd=XXXX
dev=env3

peer_public_ip=XXXX
peer_user=root
peer_pwd=passw0rd

hmc_ip=XXXX
hmc_user=hscroot
hmc_pwd=XXXX

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
        echo "HOST running: $@" >&2
        run_cmd $host_user $host_public_ip $host_pwd $@
        return $?
}

run_peer_cmd () {
        echo "PEER running: $@" >&2
        run_cmd $peer_user $peer_public_ip $peer_pwd $@
        return $?
}

check_htx_errs () {
        run_peer_cmd "hcl -query | grep $peer_dev | awk '{print \$NF}'"
        if [ $most_recent_command_output -ne 0 ]; then 
                return 1
        fi;

        run_host_cmd "hcl -query | grep $dev | awk '{print \$NF}'"
        if [ $most_recent_command_output -ne 0 ]; then 
                return 1
        fi;

        return 0;
}

start_bpftrace () {
	cat <<EOF > sk_err.bt
#include <net/sock.h>
#include <net/inet_sock.h>
#include <net/tcp.h>

kprobe:sk_error_report {
    \$sock = (struct sock *)arg0;
    \$isock = (struct inet_sock *)arg0;
    \$tsock = (struct tcp_sock *)arg0;
    printf ("%s - SK_ERR(%d) saddr=%p:%hu -snd_wnd %u\n%s\n",
                strftime("%H:%M:%S:%f", nsecs),
                \$sock->sk_err,
                \$isock->inet_saddr,
                \$isock->inet_sport,
                \$tsock->snd_wnd,
                kstack());
}
EOF

	sshpass -p "$host_pwd" scp -o StrictHostKeyChecking=no sk_err.bt $host_user@$host_public_ip:/tmp/sk_err.bt
	sshpass -p "$peer_pwd" scp -o StrictHostKeyChecking=no sk_err.bt $peer_user@$peer_public_ip:/tmp/sk_err.bt

	run_host_cmd "bpftrace /tmp/sk_err.bt > /tmp/sk_err.log" &
	run_peer_cmd "bpftrace /tmp/sk_err.bt > /tmp/sk_err.log" &
	rm sk_err.bt
}

check_bpftrace () {
	run_host_cmd "ps aux | grep 'bpftrace /tmp/sk_err.bt' | grep -v 'grep' | wc -l"
    if [ $most_recent_command_output -ne 1 ]; then
            printf "bpftrace not running on host\n"
            return 1
    fi
    run_peer_cmd "ps aux | grep 'bpftrace /tmp/sk_err.bt' | grep -v 'grep' | wc -l"
    if [ $most_recent_command_output -ne 1 ]; then
            printf "bpftrace not running on peer\n"
            return 1
    fi
}

stop_bpftrace () {
	run_host_cmd "pkill bpftrace"
	run_peer_cmd "pkill bpftrace"
}

cleanup () {

	stop_bpftrace
}

handler () {
        printf "\nCLEANING UP BEFORE EXITING!\n"
        cleanup
        exit 0
}

get_htx_peer_dev () {
	run_host_cmd "grep $dev /usr/lpp/htx/bpt | awk '{print \$2}'"
	net_id=$most_recent_command_output

	run_peer_cmd "grep ' $net_id ' /usr/lpp/htx/bpt | awk '{print \$1}'"
	echo $most_recent_command_output
}

# 1. Get name of peer device in test
peer_dev=`get_htx_peer_dev`
echo "PEER DEV IS $peer_dev"

# 2. check HTX for errs before starting
! check_htx_errs && echo "HTX ERR DETECTED!!!!!" && exit 1


# 3. start bpftrace tracking of socket errors (better than htx err reports)
! start_bpftrace && echo "Issues setting up bpftrace" && exit 1

# 4. Time to begin, if cancelled make sure to cleanup first
trap handler SIGINT

! check_bpftrace && cleanup && exit 1

