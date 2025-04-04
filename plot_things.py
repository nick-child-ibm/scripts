#!/usr/bin/python3.9
import matplotlib.pyplot as plt
import sys
import re
import numpy as np
import os

# DOCUMENTATION: vnic test w mellanox!
# PHP P9 values: https://ibm.ent.box.com/file/1421971796685 (HALEAKALA)
# PHP P10 values: Native-sriov-vnic-sea-P10 spreadsheet, downloaded (CEDARLAKE)
# VNIC ORIGINAL P9: ~/IBM/bugwork/vnic_rr_perf/plot_n_proof, max_queues, affinity on(HALEAKALA)
# VNIC ORIGINAL P10: ^
def create_grouped_barchart(ax):
	groups = ("P9", "P10")
	values_per_group = {
	    'PHP report AIX': (0, 1012.942),
	    'PHP report Linux': (558.400, 468.236),
	    'upstream': (662.645, 532.605),
	    'patched': (744.918, 783.129),
	}

	x = np.arange(len(groups))  # the label locations
	width = 0.2  # the width of the bars
	multiplier = 0

	for attribute, measurement in values_per_group.items():
	    offset = width * multiplier
	    rects = ax.bar(x + offset, measurement, width, label=attribute)
	    ax.bar_label(rects, padding=3)
	    multiplier += 1

	# Add some text for labels, title and custom x-axis tick labels, etc.
	ax.set_ylabel('thousands pps')
	ax.set_title('VNIC RR_150 100G test')
	ax.set_xticks(x + width, groups)
	ax.legend(loc='upper left')
	ax.set_ylim(0, 1100)

#DOCUMENTATION: ~/IBM/bugwork/vnic_rr_perf/plot_n_proof/proof/*napi_work
def create_percent_napi_weight(ax):
	lines = {
	"sriov (1,335,540 pps)": [4.05, 18.23, 21.28, 16.72, 10.59, 6.48, 4.24, 3.79, 1.05, 1.55, 2.73, 2.37, 1.17, 1.31, 1.08, 1.32, 0.0, 0.0, 0.01, 0.02, 0.09, 0.26, 0.52, 0.61, 0.0, 0.0, 0.0, 0.01, 0.03, 0.08, 0.14, 0.14, 0.0, 0.0, 0.0, 0.0, 0.01, 0.01, 0.03, 0.04, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.01, 0.01, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.01],
	"vnic (722,840 pps)": [5.79, 42.64, 27.09, 13.61, 6.03, 2.5, 1.1, 0.53, 0.27, 0.17, 0.11, 0.08, 0.03, 0.02, 0.02, 0.01, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	}
	color = 'b'
	for key, value in lines.items():
		ax.stem(range(0, len(value)), value , color , label=key)
		color = 'r'
	ax.legend(loc='upper left')
	ax.set_ylabel('frequency %')
	ax.set_xlabel('napi amount work scheduled')
	ax.set_title('VNIC vs SRIOV napi work')

num_plots = [1,2] # 1 by 2
fig, axs = plt.subplots(num_plots[0], num_plots[1])
create_grouped_barchart(axs[0])
create_percent_napi_weight(axs[1])
plt.show()
