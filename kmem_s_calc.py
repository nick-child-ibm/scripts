import sys



if len(sys.argv) < 2:
	print(f"USAGE: {sys.argv[0]} <file>")
	sys.exit(1)

file = sys.argv[1]
print(f"Reading {file}")
arr = []
tot = 0
with open(file) as f:
	for line in f:
		line = line.split()
		name = line[-1]
		size = line[1]
		n = line[3]
		total_size = (float(size) * float(n)) / (2**30)
		tot += total_size
		arr.append([name, total_size, size, n])
		#print(f"{name} {size} {n}")

arr.sort(key=lambda x: float(x[1]))


for n in arr:
	print(f"{n[0]}: {n[1]} GB , {n[2]} * {n[3]}")

print(f"total = {tot} GB")