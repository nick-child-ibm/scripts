# This script runs performance tests on multiple versions of one driver
# The different versions of the driver are in ${driver_dir}/${driver_file}
# The tests are run a ${iterations} times on each driver file
# The results are then averaged and can be compared by the user
# The order of execution is as follows:
# Assume drivers are A, B, C
# Assume tests are X, Y
# Assume iterations is 3
# Order of operations is: A-X, A-Y, B-X, B-Y, C-X, C-Y, repeated 2 more times

# Use `-n` command line argument to not include the default driver in the tests

import subprocess
import sys
import os
import re
import time
import numpy as np
import pandas 

driver_name = 'ibmveth'
iterations = 10
# drivers must be already in ./${driver_dir}/${driver_file}
driver_dir = '../driver_versions'
# default driver is assumed, AKA `modprobe ibmveth`
driver_files = ['tx_no_unmap', 'tx_one_ltb', 'tx_multi_q']
USING_DEFAULT_DRIVER = True
#USER TODO
iperf3_server_ip = "PUT IP HERE"
def iperf3_test_print(results):
	return f'{round(results[0], 2)} Gbs, {round(results[1], 2)} rtx'
def iperf3_test():
	# return [bitrate (in Gbits/sec), retries]
	command = f"iperf3 -c {iperf3_server_ip} -t 60"
	results = run_regex_cmd(command, r"(\d+\.\d+) Gbits/sec(?:\s+)(\d+)(?:\s+) sender")
	ret = [float(results[0][0].replace(',','')), float(results[0][1].replace(',',''))]
	return ret

trace_func_tracked = ["ibmveth_start_xmit", "ibmveth_poll"]
def trace_print(results):
	print_string = ''
	for f in range(len(trace_func_tracked)):
		print_string += f'{trace_func_tracked[f]} {round(results[f], 2)} us, '
	return print_string[:-2]
def trace_test():
	# return [avg time of trace_func_tracked]
	cmd = f"iperf3 -c {iperf3_server_ip}  -t 20"
	ftrace_dir = "/sys/kernel/debug/tracing"
	# clear old data
	assert run_cmd(f"echo 0 > {ftrace_dir}/tracing_on")
	assert run_cmd(f"echo > {ftrace_dir}/trace")
	assert run_cmd(f"echo > {ftrace_dir}/set_ftrace_filter")
	assert run_cmd(f"echo nop > {ftrace_dir}/current_tracer")
	assert run_cmd(f"echo 1 > {ftrace_dir}/options/graph-time")
	funcs_want_str = ""
	for f in trace_func_tracked:
		funcs_want_str += f + " "
	assert run_cmd(f"echo {funcs_want_str} > {ftrace_dir}/set_ftrace_filter")
	assert run_cmd(f"echo 1 > {ftrace_dir}/function_profile_enabled")
	# tracing is now on for our functions
	assert run_cmd(cmd)
	# stop tracing
	assert run_cmd(f"echo 0 > {ftrace_dir}/function_profile_enabled")
	regex_funcs = funcs_want_str[:-1].replace(" ", "|")
	# regex should return [func_name, times_called, avg_time per call]
	matches = run_regex_cmd(f"cat {ftrace_dir}/trace_stat/function*",r"(ibmveth_start_xmit|ibmveth_poll)(?:\s+)(\d+)(?:\s+)(?:\S+)(?:\s+)(?:\S+)(?:\s+)(\d+\.\d+)(?:\s+)us")
	# record [times called, avg time]
	results = []
	for init in range(len(trace_func_tracked)):
		results.append([])
	# record total number of calls
	total_calls = [0] * len(trace_func_tracked)
	for m in matches:
		f = -1
		# get function associated with this match
		for n in range(len(trace_func_tracked)):
			if m[0] == trace_func_tracked[n]:
				f = n
				break
		assert f != -1
		print(f"remove later match: {m}")
		print(f"{[float(m[1]), float(m[2])]}")
		results[f].append([float(m[1]), float(m[2])])
		total_calls[f] += float(m[1])
		print(f"{trace_func_tracked[f]} count: {m[1]} avg: {m[2]}")
	# we need to weight these averages since
	# sometimes ftrace can show wierd results like
	# FUNCTION  	COUNT 		AVG
	#   foobar		  6		   400 us
	#	foobar		 600		4 us
	# obviously the instance where foobar is called 600 times
	# is more reliable so we need to weight these AVG values by the
	# percent of the instance's count vs the total count for this function

	avg_results = []
	for f in range(len(trace_func_tracked)):
		avg_results.append(0)
		print(f"{len(results[f])} samples for {trace_func_tracked[f]} : {results[f]}")
		for i in results[f]:
			avg_results[f] += i[1] * (i[0] / total_calls[f])
		print(f"avg time for {trace_func_tracked[f]} is {avg_results[f]}")
	return avg_results

#USER TODO, must be different then iperf3 due to server side setup
# unless one is running in background then its okay just watch port overlap
qperf_server_ip = "USER TODO"
def parallel_qperf_print(results):
	return f'{round(results[0] / 1024,2)} Gb/s'
def parallel_qperf_test(n_jobs = 1, msg_size = '64K'):
	# returns [bw] summed over all parallel threads
	cmd = f"parallel --jobs {n_jobs} ../qperf/src/qperf --use_bits_per_sec -v -m {msg_size} -t 30 {qperf_server_ip} -lp {{}} tcp_bw ::: {{1966..{1966 + n_jobs - 1}}}"
	regex = r"bw(?:\s+)=(?:\s+)(\d+.\d+|\d+)(?:\s+)(G|M)b/s"
	matches = run_regex_cmd(cmd, regex)
	total = 0
	for m in matches:
		if m[1] == 'G':
			#convert to Mb's
			total += (float(m[0].replace(',','')) * 1024)
		else:
			total += float(m[0].replace(',',''))
	return [total]
def parallel_qperf_test_1_job_64K():
	return parallel_qperf_test()
def parallel_qperf_test_2_jobs_64K():
	return parallel_qperf_test(2)
def parallel_qperf_test_4_jobs_64K():
	return parallel_qperf_test(4)
def parallel_qperf_test_8_jobs_64K():
	return parallel_qperf_test(8)
def parallel_qperf_test_1_job_5M():
	return parallel_qperf_test(msg_size = '5M')
def parallel_qperf_test_2_jobs_5M():
	return parallel_qperf_test(2, '5M')
def parallel_qperf_test_4_jobs_5M():
	return parallel_qperf_test(4, '5M')
def parallel_qperf_test_8_jobs_5M():
	return parallel_qperf_test(8, '5M')
def parallel_qperf_test_1_job_1G():
	return parallel_qperf_test(msg_size = '1G')
def parallel_qperf_test_2_jobs_1G():
	return parallel_qperf_test(2, '1G')
def parallel_qperf_test_4_jobs_1G():
	return parallel_qperf_test(4, '1G')
def parallel_qperf_test_8_jobs_1G():
	return parallel_qperf_test(8, '1G')
def parallel_qperf_test_1_job_100():
	return parallel_qperf_test(msg_size = '100')
def parallel_qperf_test_2_jobs_100():
	return parallel_qperf_test(2, '100')
def parallel_qperf_test_4_jobs_100():
	return parallel_qperf_test(4, '100')
def parallel_qperf_test_8_jobs_100():
	return parallel_qperf_test(8, '100')
# test functions to run, they should return an array of floats
# this return array is the results of the performance test and 
# are averaged at the end
tests = [iperf3_test, trace_test, 
		parallel_qperf_test_1_job_64K, parallel_qperf_test_2_jobs_64K, parallel_qperf_test_4_jobs_64K, parallel_qperf_test_8_jobs_64K, 
		parallel_qperf_test_1_job_5M, parallel_qperf_test_2_jobs_5M, parallel_qperf_test_4_jobs_5M, parallel_qperf_test_8_jobs_5M,
		parallel_qperf_test_1_job_1G, parallel_qperf_test_2_jobs_1G, parallel_qperf_test_4_jobs_1G, parallel_qperf_test_8_jobs_1G,
		parallel_qperf_test_1_job_100, parallel_qperf_test_2_jobs_100, parallel_qperf_test_4_jobs_100, parallel_qperf_test_8_jobs_100
		]
# functions to return a string representing the results returned from tests
# MAKE SURE SAME ORDER
print_tests = [iperf3_test_print, trace_print, 
			parallel_qperf_print, parallel_qperf_print, parallel_qperf_print, parallel_qperf_print,
			parallel_qperf_print, parallel_qperf_print, parallel_qperf_print, parallel_qperf_print,
			parallel_qperf_print, parallel_qperf_print, parallel_qperf_print, parallel_qperf_print,
			parallel_qperf_print, parallel_qperf_print, parallel_qperf_print, parallel_qperf_print]

# returns True for $? == 0 else False
def run_cmd(cmd):
	print(f"running cmd {cmd}")
	result = os.system(cmd)
	if result == 0:
		return True
	return False

def run_regex_cmd(cmd, rgx):
	result = (subprocess.run(cmd, shell = True, capture_output = True, check = True)).stdout.decode('utf-8')
	print(f'CMD: {cmd}\n{result}')
	match = re.findall(rgx, result)
	print(f'MATCH: {match}')
	return match

def load_external_module(module_file):
	run_cmd(f'rmmod {driver_name}')
	assert run_cmd(f'insmod {module_file}'), "ERROR: could not insert module " + module_file

def get_default_driver():
	file = run_regex_cmd(f'modinfo {driver_name}', r"filename:\s*(\S*)\b")[0]
	assert file is not None, "ERROR: could not find path to default " + driver_name
	print("Default is located at " + file)
	return file

def avg_results(res, drivers):
	
	num_diff_drivers = len(drivers)
	num_diff_tests = len(tests)
	num_unique_tests = num_diff_drivers * num_diff_tests
	# get avg for every driver on test
	for driver_test in range(num_unique_tests):
		# sum all iterations of this test on this driver
		sum_res = []
		for i in range(iterations):
			sum_res.append(res[driver_test + (i * num_unique_tests)])
		avg = np.mean(np.array(sum_res), axis=0)
		res.append(avg)
def get_string_from_results(table, iteration, test_n, total_drivers, total_tests):
	# return an array of results from iteration # `iteration` of test # `test_n` for all drivers
	result = []
	for d in range(total_drivers):
		result.append(print_tests[test_n](table[ test_n + (total_tests  * d) + (iteration * total_drivers * total_tests)]))
	return result
def print_results(res, drivers):
	num_diff_drivers = len(drivers)
	num_diff_tests = len(tests)
	num_unique_tests = num_diff_drivers * num_diff_tests
	if USING_DEFAULT_DRIVER:
		col_labels = ["default"] + drivers[1:]
	else:
		col_labels = drivers
	row_labels = list(range(iterations)) + ["AVG"]
	for t in range(num_diff_tests):
		print(f"TEST: {tests[t].__name__}")
		table = []
		for i in range(iterations):
			row = get_string_from_results(res, i, t, num_diff_drivers, num_diff_tests)
			table.append(row)
		# get avg results
		row = get_string_from_results(res, iterations, t, num_diff_drivers, num_diff_tests)
		table.append(row)
		print(pandas.DataFrame(table, index=row_labels, columns=col_labels))

if "-n" in sys.argv:
	USING_DEFAULT_DRIVER = False
else:
	default_driver_file = get_default_driver()
	driver_files.insert(0, default_driver_file)
results = []
pandas.set_option('display.max_columns', None)
pandas.set_option('display.max_rows', None)
for itr in range(iterations):

	for driver in driver_files:
		if USING_DEFAULT_DRIVER and driver is default_driver_file:
			load_external_module(driver)
		else:
			load_external_module(driver_dir + "/" + driver)
		time.sleep(3)
		for test in tests:
			results.append(test())

avg_results(results, driver_files)
print_results(results, driver_files)

