#!/bin/bash

rm -rf Dirty.txt

while :
do
	cat /proc/meminfo | grep Dirty | awk '{print $2}' >> Dirty.txt
done
