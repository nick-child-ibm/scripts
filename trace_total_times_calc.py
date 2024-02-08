import sys

if (len(sys.argv) < 2):
	print("USAGE: " + sys.argv[0] + " <output from trace.sh file>")
	quit()

file = sys.argv[1]

# this dict holds "func_name": [n_count, n_time]
counter_dict = {}
for line in open(file):
	if '--------' in line or "Function" in line or not line.startswith(' ') or len(line.split()) != 8:
		continue
	func = line.split()[0]
	count = float(line.split()[1])
	time = float(line.split()[2])
	if func not in counter_dict.keys():
		counter_dict[func] = [count, time]
	else:
		counter_dict[func][0] += count
		counter_dict[func][1] += time

for k,v in counter_dict.items():
	print(f'FUNC: {k} = {round(v[1],2)} us / {v[0]} hits = AVG {round(v[1] / v[0], 2)}')
	