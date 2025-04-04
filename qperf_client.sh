#!/bin/bash
######################################################################
#                                                                    #
#             ======      ============    ==          ==             #
#               ==        ==          ==  ====      ====             #
#               ==        ==          ==  ==  ==  ==  ==             #
#               ==        ============    ==    ==    ==             #
#               ==        ==          ==  ==          ==             #
#               ==        ==          ==  ==          ==             #
#             ======      ============    ==          ==             #
#                                                                    #
######################################################################
# Licensed Materials - Property of IBM
#
# (C) COPYRIGHT International Business Machines Corp. 2000
# All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# This script is provided as-is. No support is given. Any damage
# resulting from the use or misuse of this script are not the responsibility
# of IBM. Contact Ronald.Kukuck1@ibm.com for updates/bug reports/feature requests.
#
# Program       : qprf.sh
# Author        : Ronald Kukuck
# Changes:      1.0 initial version   2020-18-02
#
#
######################################################################
#                                                                    #
# Progam runns qperf 60 sec with different message sizes in different#
# number of threads (the corresponding qperf on the server have to be#
# started manually)                                                  #
#                                                                    #
#  usage : qprf.sh  hostname   number_of_threads   message_size      #
#                                                                    #
######################################################################



qprf_port=19765
resfile=/tmp/qprf_$$_

if [ $#  -lt 3 ]
then
    echo  "Please give target LPAR name then number of threads as second and mesage size as third Parameter."
    exit
 fi


if [ $2 -lt 1 -a $2 -gt 8  ]
then
    thread_cnt=1
else
    thread_cnt=$2
fi


if [ $3 = "1K" -o $3  = "5K" -o  $3  = "5M" ]
then
     msg_sz=$3
else
     msg_sz="5M"
fi

echo "Running test with $msg_sz Message size $thread_cnt times in parallel.\n"


for (( i=1 ; i <= $thread_cnt ; i++ ))
do
   echo -n  "port=$qprf_port  "
   qperf -vvs -lp $qprf_port   $1   -ub -m $msg_sz  -t 30  tcp_bw tcp_lat > $resfile\_thread\_$i.txt &
   ((qprf_port++ ))
done


PID=$!
i=1
sp="/-\|"
echo -n ' '
while [ -d /proc/$PID ]
do
#  printf "\b${sp:i++%${#sp}:1}"
  sleep 0.2
done
echo ""

