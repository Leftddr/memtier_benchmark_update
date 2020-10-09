#!/bin/bash
FTRACE="/sys/kernel/debug/tracing"
REDIS_PATH="/home/oslab/redis-stable/src"
SP="10000"

free && sync && echo 3 > /proc/sys/vm/drop_caches && free
sleep 2

#KILL THE REDIS-SERVER
PID=`ps -aux | grep redis-server | awk '{print $2}'`
echo "kill redis-server"
sudo kill -9 $PID

#KILL THE RDB-BGSAVE
PID=`ps -aux | grep redis | awk '{print $2}'`
echo "kill bgsaave"
sudo kill -9 $PID

#KILL THE REWRITE
PID=`ps -aux | grep redis | awk '{print $2}'`
echo "kill rewriteof"
sudo kill -9 $PID

free && sync && echo 3 > /proc/sys/vm/drop_caches && free
sleep 2

sleep 3

if [ -f appendonly.aof ];then
	rm -rf appendonly.aof
fi

if [ -f dump.rdb ];then
	rm -rf dump.rdb
fi

rm -rf temp-*

echo "Copy the redis.conf"
cp redis.conf redis_"$SP".conf

if [ $1 == "rdb" ]; then
echo "save 1 $SP" >> redis_"$SP".conf
fi

if [ $1 == "aof" ]; then
echo "appendonly yes" >> redis_"$SP".conf
echo "auto-aof-rewrite-min-size 256gb" >> redis_"$SP".conf
fi

if [ $1 == "aofpreamble" ]; then
echo "appendonly yes" >> redis_"$SP".conf
echo "auto-aof-rewrite-min-size 128mb" >> redis_"$SP".conf
	if [ $2 == "nosync" ]; then
	echo "no-appendfsync-on-rewrite yes" >> redis_"$SP".conf
	else
	echo "no-appendfsync-on-rewrite no" >> redis_"$SP".conf
	fi
fi

if [ $1 == "aofrdb" ]; then
echo "save 1 $SP" >> redis_"$SP".conf
echo "appendonly yes" >> redis_"$SP".conf
echo "auto-aof-rewrite-min-size 256gb" >> redis_"$SP".conf
	if [ $2 == "nosync" ]; then
	echo "no-appendfsync-on-rewrite yes" >> redis_"$SP".conf
	else
	echo "no-appendfsync-on-rewrite no" >> redis_"$SP".conf
	fi
fi

if [ $1 == "aofrdbpreamble" ]; then
echo "save 1 $SP" >> redis_"$SP".conf
echo "appendonly yes" >> redis_"$SP".conf
echo "auto-aof-rewrite-min-size 128mb" >> redis_"$SP".conf
	if [ $2 == "nosync" ]; then
	echo "no-appendfsync-on-rewrite yes" >> redis_"$SP".conf
	else
	echo "no-appendfsync-on-rewrite no" >> redis_"$SP".conf
	fi
fi

$REDIS_PATH/redis-server ./redis_"$SP".conf &
sleep 5

PID=`ps -aux | grep redis-server | awk '{print $2}'`
LEN=`echo $PID | wc -L`

echo "$PID"
if [ $LEN -gt 7 ];then
	FIANL_PID=`echo ${PID[0]} | cut -d ' ' -f1`
	sudo echo "$FINAL_PID" > $FTRACE/set_ftrace_pid
else
	sudo echo "$PID" > $FTRACE/set_ftrace_pid
fi

#Setting Ftrace
echo "Setting Ftrace"
sudo echo "" > $FTRACE/trace
echo "Setting Ftrace Filter"
sudo echo $PID > $FTRACE/set_ftrace_pid
sudo echo "*sync*" > $FTRACE/set_ftrace_filter
sudo echo function_graph > $FTRACE/current_tracer

./memtier_benchmark -n 5000 --data-size-range=10240-10240 --ratio=1:0 --random-data --print-percentile 99 99.9 > output.txt

#cat $FTRACE/trace | awk '{print $3, $4}' > ./fsync_time.txt
