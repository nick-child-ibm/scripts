import sys
import os.path


def get_device_from_line(line):
	words = line.split()
	# we know the format is net5: or env5: or eth5: so just find the colon with one of env,net,eth
	dev_names = ['env', 'net', 'eth']
	for w in words:
		if ':' not in w:
			continue
		for d in dev_names:
			if d in w:
				return w[:-1]
	return None 

def get_time_from_line(line):
	start = line.index('[')+1
	end = line.index(']')
	return float(line[start:end])

# info is in format [sched, start, finish, rc, time_since_last_reset]
def print_reset_times(dev, info):
	print(f"{dev}:\n\tSince last reset {info[4]}\n\tSched {info[0]}\n\tStart {info[1]}\n\tEnd {info[2]} rc {info[3]}\n\tTOTAL TIME {info[2] - info[0]}")

if len(sys.argv) < 2:
	print (f"USAGE: {sys.argv[0]} <dmesg output with ibmvnic dyndbg output>")
	sys.exit(1)

path = sys.argv[1]
if not os.path.isfile(path):
	print(f"{path} is not a file")
	sys.exit(1)

# the format that we will use to track:
# "dev" = [<schedule time>, <start time>, <end time>, rc, time since last reset]
tracker = {}
with open(path, 'r') as file:
	for l in file.readlines():
		if "ibmvnic" not in l:
			continue
		
		dev = get_device_from_line(l)
		if not dev:
			continue
		time = get_time_from_line(l)
		if "Scheduling reset" in l:
			if dev not in tracker.keys() or tracker[dev][2] == 0:
				tracker[dev] = [time, 0, 0, 0, 0]
			else:
				tracker[dev] = [time, 0 , 0 , 0, time - tracker[dev][2]]
		elif "Reset reason" in l:
			if dev not in tracker.keys() or tracker[dev][0] == 0:
				print(f"skipping unmatched reset for {l}")
				continue;
			tracker[dev][1] = time
		elif "Reset done" in l:
			if dev not in tracker.keys() or tracker[dev][1] == 0:
				print(f"skipping unmatched reset for {l}")
				continue;
			tracker[dev][2] = time
			tracker[dev][3] = l.split()[-1]
			print_reset_times(dev, tracker[dev])


