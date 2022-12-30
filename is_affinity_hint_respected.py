#!/usr/bin/env python
import os
import sys
import subprocess
from subprocess import PIPE

def run_command(command, rc_expect=0):
    # exit if not the return value we expect
    cmd_rst = subprocess.run(command.split(), stdout=PIPE, stderr=PIPE)
    if cmd_rst.returncode != rc_expect:
        print(f"Command failed with rc {cmd_rst.returncode}")
        print(f"STDERR:\n{cmd_rst.stderr.decode()}")
        print(f"STDOUT:\n{cmd_rst.stdout.decode()}")
        quit(1)
    return cmd_rst.stdout.decode().strip()

def get_irqs_for_drc(drc):
    cmd_out = run_command(f"cat /proc/interrupts").split('\n')
    proc_irqs = [line for line in cmd_out if drc+"-" in line]
    irqs = [line.split(':')[0].strip() for line in proc_irqs]
    return irqs

def expected_num_cpu_per_irq(n_irqs):
    n_cpu = int(run_command("nproc"))
    cpu_per_irq = max(1, n_cpu // n_irqs)
    # give one extra for stragglers
    return range(cpu_per_irq, cpu_per_irq+2)
    
def is_irq_respected(irq, n_cpu_expect_range):
    affinity_hint = run_command(f'cat /proc/irq/{irq}/affinity_hint')
    smp_affinity = run_command(f'cat /proc/irq/{irq}/smp_affinity')
    smp_affinity_list = run_command(f'cat /proc/irq/{irq}/smp_affinity_list')
    # is hint being applied
    if affinity_hint != smp_affinity:
        print(f"irq: {irq} affinity_hint: {affinity_hint} != smp_affinity: {smp_affinity}")
        return False
    
    # does n cpu's being used match what is expected
    n_cpus = 0
    for cpu_range in smp_affinity_list.split(','):
        if '-' not in cpu_range:
            n_cpus += 1
            continue
        n_cpus += abs(int(cpu_range.split('-')[0]) - int(cpu_range.split('-')[1])) + 1
    if n_cpus not in n_cpu_expect_range:
        print(f"irq: {irq} smp_affinity_list: {smp_affinity_list} does not match the expected number of cpu's that the irq should use ({n_cpu_expect_range})")
        return False
    return True

if len(sys.argv) < 2:
    print(f"USAGE: {sys.argv[0]} <dev>")
    quit(1)

dev = sys.argv[1]
drc = run_command(f"ofpathname {dev}")
drc = drc[drc.rfind('@')+1:]
print(f"drc is {drc}")
irqs = get_irqs_for_drc(drc)
print(f"irqs are {irqs}")
range_ncpus = expected_num_cpu_per_irq(len(irqs))
print(f"num cpus per irq should be in {range_ncpus}")
pass_flag = True
for irq in irqs:
    if not is_irq_respected(irq, range_ncpus):
        print(f"IRQ {irq} is not respected")
        pass_flag = False

if pass_flag:
    quit(0)
else:
    quit(1)

