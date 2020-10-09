DSHAPE="NOT-RANDOM RANDOM"
METHOD="N RDB AOF AOFPREAMBLE AOFRDB AOFRDBPREAMBLE"
SP="10000"
REDIS_PATH="/home/oslab/redis-stable/src"
OP_SIZE=10240
OP_NUM=1000000
DIR="result"
OUTPATH="redis_RDB/redis_test_RDB"
OUTPATH2="memtier_result"_"$OP_SIZE"_"$OP_NUM"_no_overwrite_get
GETSET="GET"
MULTITHREAD="MULTI"

if [ ! -d $OUTPATH2 ];then
	mkdir $OUTPATH2
fi

#for num in $FOR; do
for method in $METHOD; do
    for thread in $MULTITHREAD; do
		for getset in $GETSET; do

            for i in `seq 1 3`; do
                PID=`ps -aux | grep redis | awk '{print $2}'`
                echo "Kill the Redis-server"
                sudo kill -9 $PID
                sleep 1
            done

            echo "Copy the redis.conf"
            cp redis.conf redis_"$SP".conf

            if [ $method == "RDB" ]; then
            echo "save 1 $SP" >> redis_"$SP".conf
            fi

            if [ $method == "AOF" ]; then
            echo "appendonly yes" >> redis_"$SP".conf
            echo "auto-aof-rewrite-min-size 256gb" >> redis_"$SP".conf
            fi

            if [ $method == "AOFPREAMBLE" ]; then
                echo "appendonly yes" >> redis_"$SP".conf
                echo "auto-aof-rewrite-min-size 64mb" >> redis_"$SP".conf
                if [ $2 == "nosync" ]; then
                echo "no-appendfsync-on-rewrite yes" >> redis_"$SP".conf
                else
                echo "no-appendfsync-on-rewrite no" >> redis_"$SP".conf
                fi
            fi

            if [ $method == "AOFRDB" ]; then
            echo "save 1 $SP" >> redis_"$SP".conf
            echo "appendonly yes" >> redis_"$SP".conf
            echo "auto-aof-rewrite-min-size 256gb" >> redis_"$SP".conf
                if [ $2 == "nosync" ]; then
                echo "no-appendfsync-on-rewrite yes" >> redis_"$SP".conf
                else
                echo "no-appendfsync-on-rewrite no" >> redis_"$SP".conf
                fi
            fi

            if [ $method == "AOFRDBPREAMBLE" ]; then
            echo "save 1 $SP" >> redis_"$SP".conf
            echo "appendonly yes" >> redis_"$SP".conf
            echo "auto-aof-rewrite-min-size 64mb" >> redis_"$SP".conf
                if [ $2 == "nosync" ]; then
                echo "no-appendfsync-on-rewrite yes" >> redis_"$SP".conf
                else
                echo "no-appendfsync-on-rewrite no" >> redis_"$SP".conf
                fi
            fi

            if [ -f appendonly.aof ];then
                echo "Remove AOF file"
                rm -rf appendonly.aof
            fi

            if [ -f dump.rdb ];then
                echo "Remove Dump file"
                rm -rf dump.rdb
            fi

            echo "Remove Temp-* file"
            rm -rf temp-*

            free && sync && echo 3 > /proc/sys/vm/drop_caches && free
            sleep 2
            
            $REDIS_PATH/redis-server ./redis_"$SP".conf &
            sleep 5

            FNAME=memtier_"$OP_SIZE"_"$OP_NUM".lat

			if [ $getset == "GET" ]; then
				if [ $thread == "MULTI" ]; then
					echo "./memtier_benchmark -t 1 -c 1 -n $OP_NUM --data-size-range="$OP_SIZE"-"$OP_SIZE" --ratio=1:0 --random-data"
					./memtier_benchmark -t 1 -c 1 -n $OP_NUM --data-size-range="$OP_SIZE"-"$OP_SIZE" --ratio=1:0 --random-data --key-pattern=S:S
					sleep 2
					echo "./memtier_benchmark -n $(($OP_NUM/200)) --data-size-range="$OP_SIZE"-"$OP_SIZE" --ratio=0:1"
					./memtier_benchmark -n $(($OP_NUM/200)) --ratio=0:1 --print-percentiles 90,99,99.9,99.99 --hdr-file-prefix cdf > $FNAME
				elif [ $thread == "SINGLE" ]; then
					echo "./memtier_benchmakr -t 1 -c 1 -n $OP_NUM --data-size-range="$OP_SIZE"-"$OP_SIZE" --ratio=1:0 --random-data"	
					./memtier_benchmark -t 1 -c 1 -n $OP_NUM --ratio=1:0 --data-size-range="$OP_SIZE"-"$OP_SIZE" --random-data --key-pattern=S:S
					sleep 2
					echo "./memtier_benchmakr -t 1 -c 1 -n $OP_NUM --data-size-range="$OP_SIZE"-"$OP_SIZE""
					./memtier_benchmark -t 1 -c 1 -n $OP_NUM --ratio=0:1 --print-percentiles 90,99,99.9,99.99 --hdr-file-prefix cdf > $FNAME
				fi
			elif [ $getset == "SET" ]; then
				if [ $thread == "MULTI" ]; then
					echo "./memtier_benchmark -t 1 -c 1 -n $(($OP_NUM/200)) --data-size-range="$OP_SIZE"-"$OP_SIZE" --ratio=1:0 --random-data"
					./memtier_benchmark -n $(($OP_NUM/200)) --data-size-range="$OP_SIZE"-"$OP_SIZE" --ratio=1:0 --key-pattern=S:S --random-data --print-percentiles 90,99,99.9,99.99 --hdr-file-prefix cdf > $FNAME
				elif [ $thread == "SINGLE" ]; then
					echo "./memtier_benchmark -t 1 -c 1 -n $OP_NUM --data-size-range="$OP_SIZE"-"$OP_SIZE" --ratio=1:0 --random-data"
					./memtier_benchmark -t 1 -c 1 -n $OP_NUM --data-size-range="$OP_SIZE"-"$OP_SIZE" --ratio=1:0 --key-pattern=S:S --random-data --print-percentiles 90,99,99.9,99.99 --hdr-file-prefix cdf > $FNAME
				fi
			fi

            sleep 2

            DNAME="$DIR"_"ops"_"$OP_NUM"_"$getset"_"$thread"_"$1"

            if [ -d "$OUTPATH2"/"$DNAME" ]; then
                sudo rm -rf "$OUTPATH2"/"$DNAME"
            fi

            echo "Make Directory"
            mkdir "$OUTPATH2"/"$DNAME"

            LINE_NUM=`cat cdf_FULL_RUN_1.txt | wc -l`
            sleep 1
            cat cdf_FULL_RUN_1.txt | awk '{print $1, $2}' > cdf_FULL_RUN_1_output.txt
            TOTAL_LINE_NUM=$((LINE_NUM - 3))

            head -n $TOTAL_LINE_NUM cdf_FULL_RUN_1_output.txt > cdf_latency.txt
            rm -rf cdf_FULL_RUN_1_output.txt

            sleep 1

            mv $FNAME "$OUTPATH2"/"$DNAME"/
            mv cdf* "$OUTPATH2"/"$DNAME"/

            echo "Move the File"
            if [ -d "$OUTPATH2"/"$method" ]; then
                mv "$OUTPATH2"/"$DNAME" "$OUTPATH2"/"$method"/
            else
                mkdir "$OUTPATH2"/"$method"
                mv "$OUTPATH2"/"$DNAME" "$OUTPATH2"/"$method"/
            fi	

            sudo rm -rf "$OUTPATH2"/"$DNAME"

            sleep 3
		done
    done
done
#done

