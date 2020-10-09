OP_SIZE=10240
OP_NUM=1000000
#OP_NUM=1000000
SAVE_PERIOD="10000"
REDIS_HOME="/mnt/e/algorithm/redis-stable"
RESULT_DIR="./result"

if [[ ! -d $RESULT_DIR ]]; then
    echo "result directory doesn't exits"
    mkdir $RESULT_DIR
fi

for sp in $SAVE_PERIOD; do

    ## Set up the redis.conf
    cp redis.conf redis_"$sp".conf
    echo "save 1 $sp" >> redis_"$sp".conf
    #echo "appendonly yes" >> redis_"$sp".conf
    ## cp tmp $REDIS_HOME/redis.conf


    ## Run Clean up
    if [ -f ./dump.rdb ]; then
        echo "rm ./dump.rdb"
        rm ./dump.rdb
    fi

    if [ -f ../redis-stable/src/dump.rdb ]; then
        echo "rm ./redis-stable/src/dump.rdb"
        rm ../redis-stable/src/dump.rdb
    fi

    if [ -f ./appendonly.aof ]; then
        echo "rm ./appendonly.aof"
        rm ./appendonly.aof
    fi

    if [ -f ../redis-stable/src/appendonly.aof ]; then
        echo "rm ./redis-stable/src/appendonly.aof"
        rm ../redis-stable/src/appendonly.aof
    fi

    ## Run the redis server
    PID=`ps aux | grep redis-server | awk '{print $2}'`
    echo kill -9 $PID
    sudo kill -9 $PID
    ps aux | grep "redis"

    sleep 5

    echo "Running a redis-server ..."
    #$REDIS_HOME/src/redis-server ./redis.conf &
    $REDIS_HOME/src/redis-server ./redis_"$sp".conf &
    ps aux | grep redis

    sleep 5

    echo "Executing Membenchmark"

    FNAME=$RESULT_DIR/memtier_"$sp"_"$OP_SIZE"_"$OP_NUM".lat
    echo "./memtier_benchmark -t 1 -c 1 -n $OP_NUM --data-size-range="$OP_SIZE
"-"$OP_SIZE" --ratio=1:0 > $FNAME"
    ./memtier_benchmark -t 1 -c 1 -n $OP_NUM --data-size-range="$OP_SIZE"-"$OP_SIZE" --ratio=1:0 --print-percentiles 90,99,99.9,99.99 --hdr-file-prefix cdf > $FNAME

    cp redis_"$sp".conf ../redis-stable/
    mv ../redis-stable/redis_"$sp".conf ../redis-stable/redis.conf
    rm redis_"$sp".conf
#
done

if [[ -d $RESULT_DIR ]]; then
    echo "result directory exists"
    mv $RESULT_DIR $RESULT_DIR_`date +%m%d%H%M%S`
fi
