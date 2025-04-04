#!/usr/bin/python3.9

#output from bpftrace -e 'tracepoint:napi:napi_poll { @[args->work] = count(); }' &
def calc_percs(inp):
	perc = [0.0] * 65
	total = 0
	for l in inp.splitlines():
		if ':' not in l:
			continue
		total += int(l.split(':')[1])

	for l in inp.splitlines():
		if ':' not in l:
			continue
		n_hits = int(l.split(':')[1])
		work = int(l[l.index('[')+1:l.index(']')])
		perc[work] = round(float(n_hits*100/total), 2) 
	return perc
inp2="""
@[24]: 1
@[25]: 1
@[33]: 1
@[26]: 1
@[23]: 3
@[22]: 7
@[20]: 10
@[21]: 10
@[19]: 16
@[18]: 45
@[17]: 59
@[16]: 124
@[15]: 196
@[13]: 630
@[14]: 632
@[12]: 1294
@[11]: 2969
@[10]: 4135
@[9]: 6382
@[8]: 10333
@[7]: 20076
@[6]: 41794
@[5]: 94465
@[0]: 219065
@[4]: 228230
@[3]: 515208
@[2]: 1025683
@[1]: 1614218
"""
inp="""
@[33]: 1
@[24]: 1
@[59]: 1
@[16]: 2
@[51]: 3
@[43]: 5
@[60]: 6
@[25]: 9
@[52]: 10
@[34]: 11
@[61]: 14
@[17]: 15
@[62]: 24
@[53]: 41
@[26]: 43
@[44]: 46
@[35]: 52
@[63]: 60
@[54]: 93
@[55]: 117
@[45]: 141
@[18]: 162
@[36]: 175
@[64]: 255
@[27]: 284
@[46]: 288
@[47]: 341
@[37]: 454
@[19]: 721
@[38]: 888
@[28]: 1057
@[39]: 1150
@[29]: 2653
@[20]: 2872
@[30]: 4397
@[31]: 4422
@[21]: 8186
@[22]: 16163
@[23]: 18955
@[8]: 33022
@[14]: 33680
@[12]: 36641
@[13]: 41087
@[15]: 41439
@[9]: 48705
@[11]: 74187
@[10]: 85462
@[7]: 118638
@[0]: 127012
@[6]: 132684
@[5]: 202978
@[4]: 331665
@[3]: 523775
@[1]: 571148
@[2]: 666645"""

print(f"{calc_percs(inp)}")
print(f"{calc_percs(inp2)}")