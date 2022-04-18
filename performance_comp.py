# This script runs performance tests on multiple versions of one driver
# The different versions of the driver are in ${driver_dir}/${driver_file}
# The tests are run a ${iterations} times on each driver file
# The results are then averaged and can be compared by the user
import subprocess
import sys
import os
import re
import time
import numpy as np
import pandas 

driver_name = 'ibmveth'
iterations = 3
# drivers must be already in ./${driver_dir}/${driver_file}
driver_dir = '../driver_versions'
# default driver is assumed, AKA `modprobe ibmveth`
driver_files = ['tx_no_unmap', 'tx_one_ltb', 'tx_multi_q']

def iperf3_test_print(results):
	return f'{round(results[0], 2)} Gbs, {round(results[1], 2)} retries'
def iperf3_test():
	# return [bitrate (in Gbits/sec), retries]
	command = "iperf3 -c  9.40.195.146 -t 2"
	results = run_regex_cmd(command, r"(\d+\.\d+) Gbits/sec(?:\s+)(\d+)(?:\s+) sender")
	ret = [float(results[1]), float(results[2])]
	print(f"RET {ret}")
	return ret

# test functions to run, they should return an array of floats
# this return array is the results of the performance test and 
# are averaged at the end
tests = [iperf3_test]
# functions to return a string representing the results returned from tests
print_tests = [iperf3_test_print]

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
	match = re.search(rgx, result)
	print(f'MATCH: {match}')
	return match

def load_external_module(module_file):
	run_cmd(f'rmmod {driver_name}')
	assert run_cmd(f'insmod {module_file}'), "ERROR: could not insert module " + module_file

def get_default_driver():
	file = run_regex_cmd(f'modinfo {driver_name}', r"filename:\s*(\S*)\b")[1]
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
	headers = ["iteration", "default"] + drivers[1:]
	for t in range(num_diff_tests):
		print(f"TEST: {tests[t].__name__}")
		table = []
		for i in range(iterations):
			row = get_string_from_results(res, i, t, num_diff_drivers, num_diff_tests)
			row.insert(0 , i)
			table.append(row)
		# get avg results
		row = get_string_from_results(res, iterations, t, num_diff_drivers, num_diff_tests)
		row.insert(0 , "AVG")
		table.append(row)
		print(pandas.DataFrame(table, columns=headers))

default_driver_file = get_default_driver()
driver_files.insert(0, default_driver_file)
results = []
pandas.set_option('display.max_columns', None)
pandas.set_option('display.max_rows', None)
for itr in range(iterations):

	for driver in driver_files:
		if driver is default_driver_file:
			load_external_module(driver)
		else:
			load_external_module(driver_dir + "/" + driver)
		time.sleep(3)
		for test in tests:
			results.append(test())

avg_results(results, driver_files)
print_results(results, driver_files)

