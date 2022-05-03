import matplotlib.pyplot as plt
import sys
import re
import numpy

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
def parse_testname(name):
	assert "parallel_qperf_test" in name
	print(name)
	match = re.findall(r"test_(\d+)_(?:job|jobs)_(.+)", name)
	assert match is not None
	print(match)
	return match[0][0], match[0][1]

def parse_file(f):
	at_results = False
	test_name = None
	n_jobs = -1
	p_size = -1
	driver_versions = []
	expect_more_drivers = False
	with open(f, 'r') as file:
		for line in file:
			# if at a test result
			if at_results == False and 'TEST:' in line:
				at_results = True
				l = line.split()
				test_name = l[1]
				# if it is a qperf test then keep going
				if "qperf" in test_name:
					n_jobs, p_size = parse_testname(test_name)
					print(f"parsing test w {n_jobs} jobs and {p_size} size")
					# initialize this p_size if necessary
					if results.get(p_size) is None:
						results[p_size] = {}
				# if not a qperf result then keep parsing, we don't care about this test
				else:
					at_results = False
			# if we know n_jobs and p_size but not driver_versions then we are at the line that says the driver versions
			elif at_results == True and len(driver_versions) == 0:
				# the \ character will print if the line is not finished this means there are more driver versions
				if '\\' in line:
					expect_more_drivers = True
					line = line[:line.index('\\')]
				else:
					expect_more_drivers = False
				driver_versions = line.split()
				for d in driver_versions:
					# initialize dictionary array for this driver version if necessary
					if results[p_size].get(d) is None:
						results[p_size][d] = {}
					# we already know we have to initialize the n_jobs array since p_size, driver, n_jobs is unique in output
					results[p_size][d][n_jobs] =  []
			# else if we are in the actual test results
			elif at_results == True:
				nums = line.split()[1::2]
				# we know result nums correspond directly to order in our dictionary
				itr = 0
				for driver_dicts in driver_versions:
					results[p_size][driver_dicts][n_jobs].append(nums[itr])
					itr += 1
			# if we are at the end of the results but the next line will have more drivers and results, keep n_jobs and  p_size but reset driver versions
			if at_results == True and expect_more_drivers == True and 'AVG' in line:
				driver_versions = []
			# if we are at the last results of a test then reset flag for new test next line
			if at_results == True and expect_more_drivers == False and 'AVG' in line:
				print(f"results for {n_jobs} jobs and {p_size} size are:")
				for d in results[p_size]:
					print(f"{d}: {results[p_size][d][n_jobs]}")
				at_results = False
				n_jobs = -1
				p_size = -1
				driver_versions = []


def create_plots(file):
	n_plots = len(results)
	fig, plots = plt.subplots(nrows=1, ncols=n_plots)
	plt.suptitle(f"Plot of results file: {file}")
	color_arr = ['b', 'r', 'm', 'y', 'g', 'k']
	plot_itr = 0
	# for every packet size, make a plot
	for p_size in results:
		# for every driver make a line
		line_itr = 0
		for driver in results[p_size]:
			x_axis = []
			y_axis = []
			# array of arrays holding all data measurments for each n_jobs
			full_data = []
			# for every n_job make a point on the line
			for jobs in results[p_size][driver]:
				x_axis.append(int(jobs))
				data = results[p_size][driver][jobs][len(results[p_size][driver][jobs]) - 1]
				n_arr = numpy.array(results[p_size][driver][jobs][:-1]).astype(float)
				full_data.append(n_arr)
				# for all the measurements for this n_job, store it
				y_axis.append(float(data))
			print(f"plotting for {plot_itr}: x={x_axis} y={y_axis}")
			color = color_arr[line_itr % len(color_arr)]
			plots[plot_itr].plot(x_axis, y_axis, 'o-', label = driver, color = color )
			if SHOW_MIN_MAX:
				mins = []
				maxs = []
				for point in range(len(full_data)):
					mini = full_data[point].min()
					maxi = full_data[point].max()
					mins.append(y_axis[point] - mini)
					maxs.append(maxi - y_axis[point])
				plots[plot_itr].errorbar(x_axis, y_axis, color = color, yerr=[mins, maxs], capsize=3, elinewidth=1, markeredgewidth=1, lw=1)
			line_itr += 1
		plots[plot_itr].set(title = f"Packet size {p_size} bytes", xlabel="N jobs", ylabel="Bandwidth (Gbit/s)")
		plots[plot_itr]
		plot_itr += 1
	
	handles, labels = plots[plot_itr-1].get_legend_handles_labels()
	fig.legend(handles, labels, loc='lower right')
	plt.show()

if (len(sys.argv) < 2):
	print("USAGE: " + sys.argv[0] + " <output file from performance_comp.py>\nadd -m to show min/max")
	quit()

for flag in sys.argv[2:]:
	if '-s' in flag:
		SHOW_STD_DEV = True
	if '-m' in flag:
		SHOW_MIN_MAX = True
file = sys.argv[1]
parse_file(file)
create_plots(file)
