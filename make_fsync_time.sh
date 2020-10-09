
FTRACE="/sys/kernel/debug/tracing"
cat $FTRACE/trace | awk '{print $3, $4}' > ./fsync_time.txt
