#! /usr/local/bin/python3
import subprocess
import sys

if len(sys.argv) <= 1:
    repeat = 2
    count = 100
else:
    repeat = int(sys.argv[1])
    count = int(sys.argv[2])
for i in range(repeat):
    subprocess.call(['./process.py', str(count)])
