#!/bin/bash

# READ AND THANKS TO https://www.brendangregg.com/blog/2014-10-31/cpi-flame-graphs.html
CMD="$@"
FLAME="flame/FlameGraph/"
#EVENT1="pm_1plus_ppc_cmpl:k"
#EVENT2="cycles:k" # an event1 implys and event2 but not vise versa
EVENT1="instructions:k"
EVENT2="cycles:k"
PERF="perf record -a -e $EVENT1,$EVENT2 -g"
echo "RUNING $PERF $CMD" 
$PERF $CMD

# make perf.data human readable 
perf script > perf_script.data
echo "running flame scripts"

# now we need to seperate into 2 different files
$FLAME/stackcollapse-perf.pl --event-filter=$EVENT1 perf_script.data > folded_ev1
$FLAME/stackcollapse-perf.pl --event-filter=$EVENT2 perf_script.data > folded_ev2

# diffolded makes one line hold a stack entry and 2 values (instead of just one)
$FLAME/difffolded.pl folded_ev1 folded_ev2 > out.perf-folded
# finally we can make the graph
$FLAME/flamegraph.pl --title "$EVENT2 during $@" --subtitle "RED: $EVENT2 &lt; $EVENT1" out.perf-folded > perf.svg

echo "done"
