#! /usr/local/bin/python3
import datetime
import subprocess
import sys

# Do experiments many time
time = datetime.datetime.today()
time_fmt = '%Y%m%d-%H%M%S'
path = time.strftime(time_fmt)
# reuilt files are in 'path/'
result_file = path + '-result'
subprocess.call(['mkdir', path])
argvs = sys.argv
if len(argvs) <= 1:
    count = 2
else:
    count = int(argvs[1])
for i in range(count):
    for mnode_num in range(2, 21, 2):
        subprocess.call(['ns', 'camera.tcl', str(mnode_num), result_file])

# Process the results
rf = open(result_file, 'r')
emt_file = open('m_num-s_vs_emt', 'w')
tmd_file = open('m_num-s_vs_tmd', 'w')
emt = dict()
tmd = dict()
for line in rf:
    results = line.split()
    var = int(results[0])
    time = float(results[1])
    dist = float(results[2])
    if var not in emt.keys():
        emt[var] = 0.0
        tmd[var] = 0.0
    emt[var] += time
    tmd[var] += dist
vars = sorted(emt.keys())
for var in vars:
    #print('{0} {1} {2}'.format(var, emt[var]/count, tmd[var]/count))
    emt_file.write('{0} {1:.1f}\n'.format(var, emt[var] / count))
    tmd_file.write('{0} {1:.3f}\n'.format(var, tmd[var] / count))
emt_file.close()
tmd_file.close()
rf.close()
subprocess.call(['mv', result_file, path])
subprocess.call(['mv', emt_file.name, path])
subprocess.call(['mv', tmd_file.name, path])
