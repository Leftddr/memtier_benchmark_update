import sys
import time

fp = open('fsync_time.txt', 'r')

total_time = 0.0
line = fp.readline()
while True:
    if line == None or line == "":
        break
    line_split = line.split(' ')
    try:
        time_ = float(line_split[0])
        if line_split[1] == "us\n":
            total_time += time_
        elif line_split[1] == "ms\n":
            total_time += (time_ * 1000)
    except ValueError:
        line = fp.readline()
        continue
    line = fp.readline()

print(total_time)
fp.close()
