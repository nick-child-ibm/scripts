import matplotlib.pyplot as plt
import sys
import re
import numpy
import os
# this script builds plots from the output of performance_comp.py
# Specifically it looks at the results of parallel_qperf_test_<x>_jobs_<s>
# it will build a plot for every unique <s> representing the size of the packet being tested
# the x axis will be the number of jobs, <x>, and the y axis will be the thorughput
# multicolored lines will differentiate between different driver versions

# TODO: 
# 1. get number of drivers
# 2. get number of plots (sizes)
# 3. make array [packet-size,
#						[driver,
#							[<n_jobs>, 
#								[results, AVG]
#							]
#						]
#				]
# every packet size is its own graph
#	every driver is its own line in the graph
#		every n_job is its own point on the line
#			every result is a standard deviation for that point
results = {}
SHOW_MIN_MAX = False
SHOW_STD_DEV = False

def parse_dir(d):
	tests = os.listdir(d)
	print(f"Tests are {os.listdir(d)}")
	for test in tests:
		i_result = []
		iterations = os.listdir(f"{d}/{test}")
		for i in iterations:
			file = f"{d}/{test}/{i}"
			for line in open(file):
				if "[SUM] 0.00-10." in line:
					i_result.append(float(line.split()[5]))
		i_result.sort()
		results[test] = i_result
		print(f"results for {test}: {i_result}")



def create_plots(dir):
	n_plots = len(results)
	fig, plots = plt.subplots(nrows=1, ncols=1)
	plt.suptitle(f"Plot of results file: {dir}")
	color_arr = ['b', 'r', 'm', 'y', 'g', 'k']
	# for every test make a line
	line_itr = 0
		# UNCOMMENT FOR LINE GRAPH
	# for test in results.keys():
	# 	x_axis = list(range(1,len(results[test])+1))
	# 	y_axis = results[test]
	# 	print(f"plotting: x={x_axis} y={y_axis}")
	# 	#color = color_arr[line_itr % len(color_arr)]
	# 	plots.plot(x_axis, y_axis, 'o-', label = test )
	# plots.set(title = f"Sorted throughput over several iterations", xlabel="iteration", ylabel="Bandwidth (Gbit/s)")	
	# handles, labels = plots.get_legend_handles_labels()
	# fig.legend(handles, labels, loc='lower right')

	bar_dist = 0.2
	num_bars = 3
	max_y = []
	min_y = []
	avg_y = []
	x_axis = numpy.arange(len(results))

	min_min = 100
	for test in results.keys():
		if min_min > results[test][0]:
			min_min = results[test][0]
		max_y.append(results[test][-1])
		min_y.append(results[test][0])
		avg_y.append(numpy.average(results[test]))

	avg_y, min_y, max_y, keys = zip(*sorted(zip(avg_y, min_y, max_y, results.keys())))
	plots.bar(x_axis, min_y, width = bar_dist, label = "min")
	plots.bar([x + (1 * bar_dist) for x in x_axis], avg_y, width = bar_dist, label="avg")
	plots.bar([x + (2 * bar_dist) for x in x_axis], max_y, width = bar_dist, label="max")

	for i in range(len(keys)):
		plots.text((x_axis[i]) - (bar_dist / 2), min_y[i] + 0.1, int(min_y[i]))
		plots.text((x_axis[i]) + (1 * bar_dist) - (bar_dist / 2), avg_y[i] + 0.1, int(avg_y[i]))
		plots.text((x_axis[i]) + (2*bar_dist) - (bar_dist / 2), max_y[i] + 0.1, int(max_y[i]))

	plots.set_xticks([x + (1 * bar_dist) for x in x_axis])
	plots.set_xticklabels(keys)
		#color = color_arr[line_itr % len(color_arr)]
	plots.set(title = f"Sorted throughput over {len(next(iter(results.values())))} iterations", xlabel="config type", ylabel="Bandwidth (Gbit/s)", ylim = 14)	
	handles, labels = plots.get_legend_handles_labels()
	fig.legend(handles, labels, loc='upper right')
	
	plt.show()

if (len(sys.argv) < 2):
	print("USAGE: " + sys.argv[0] + " <test dir from./veth_perf_test.sh>\n\t-m to show min/max")
	quit()

for flag in sys.argv[2:]:
	if '-s' in flag:
		SHOW_STD_DEV = True
	if '-m' in flag:
		SHOW_MIN_MAX = True
log_dir = sys.argv[1]
parse_dir(log_dir)
create_plots(log_dir)
