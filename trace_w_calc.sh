#!/bin/bash

# this script will generate tracing information on FUNCS
# to run use ./trace.sh <cmd>
# command will be what is run while tracing is enabled
# the output is in trace_outputs
# on each run, 2 files are made, one trace has funtion times
# that include the times of functions called inside that function
# the other excludes this time

# By Nick Child 

THIS_DIR=`readlink -f $(dirname "$0")`
TIME=$(date -d "today" +"%Y%m%d%H%M")
FUNCS=':mod:ibmvnic'
echo tracing ${@:1}
echo output is in ${THIS_DIR}/trace_outputs/${TIME}-\*
[ ! -d "${THIS_DIR}/trace_outputs" ] && mkdir ${THIS_DIR}/trace_outputs

cd /sys/kernel/debug/tracing
echo 0 > tracing_on
echo > trace
echo nop > current_tracer
echo 1 > options/graph-time;

echo ${FUNCS}  > set_ftrace_filter
echo 1 > function_profile_enabled
${@:1} > ${THIS_DIR}/trace_outputs/tmp
echo 0 > function_profile_enabled

echo inclusive results from cmd: ${@:1} > ${THIS_DIR}/trace_outputs/${TIME}-inclusive.txt
cat trace_stat/function* >> ${THIS_DIR}/trace_outputs/${TIME}-inclusive.txt
cat ${THIS_DIR}/trace_outputs/tmp >> ${THIS_DIR}/trace_outputs/${TIME}-inclusive.txt

echo 0 > options/graph-time;
echo 1 > function_profile_enabled
${@:1} > ${THIS_DIR}/trace_outputs/tmp
echo 0 > function_profile_enabled

echo exclusive results from cmd: ${@:1} > ${THIS_DIR}/trace_outputs/${TIME}-exclusive.txt
cat trace_stat/function* >> ${THIS_DIR}/trace_outputs/${TIME}-exclusive.txt
cat ${THIS_DIR}/trace_outputs/tmp >> ${THIS_DIR}/trace_outputs/${TIME}-exclusive.txt

rm ${THIS_DIR}/trace_outputs/tmp
echo "EXCLUSIVE:" > ${THIS_DIR}/trace_outputs/${TIME}-totals 
python3 ${THIS_DIR}/trace_total_times_calc.py ${THIS_DIR}/trace_outputs/${TIME}-exclusive.txt >> ${THIS_DIR}/trace_outputs/${TIME}-totals
echo "INCLUSIVE:" >> ${THIS_DIR}/trace_outputs/${TIME}-totals
python3 ${THIS_DIR}/trace_total_times_calc.py ${THIS_DIR}/trace_outputs/${TIME}-inclusive.txt >> ${THIS_DIR}/trace_outputs/${TIME}-totals


