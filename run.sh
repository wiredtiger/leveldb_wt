#!/bin/sh

# Run Wired Tiger Level DB benchmark.
# Assumes that a pre-built Wired Tiger library exists in ../wiredtiger.
# Assumes that the Wired Tiger build is shared, not static.
# but works if it is static.

WT_PATH="../wiredtiger/build_posix"
BDB_PATH="../../db-5.3.21/build_unix"
SNAPPY_PATH="ext/compressors/snappy/.libs/"

test_compress()
{
	if [ ! -e "$WT_PATH/$SNAPPY_PATH/libwiredtiger_snappy.so" ]; then
		echo "Snappy compression not included in Wired Tiger."
		echo "Could not find $WT_PATH/$SNAPPY_PATH/libwiredtiger_snappy.so"
		echo `$WT_PATH/$SNAPPY_PATH/`
		exit 1
	fi
}

if [ `uname` == "Darwin" ]; then
	lib_path="DYLD_LIBRARY_PATH=$WT_PATH/.libs:$WT_PATH/$SNAPPY_PATH"
	bdblib_path="DYLD_LIBRARY_PATH=$BDB_PATH/.libs:"
else
	lib_path="LD_LIBRARY_PATH=$WT_PATH/.libs:$WT_PATH/$SNAPPY_PATH"
	bdblib_path="LD_LIBRARY_PATH=$BDB_PATH/.libs:"
fi

#
# Test to run is one of (default big):
# small - 4Mb cache (or 6Mb, smallest WT can use), no other args.
# big|large - 128Mb cache,
# val - 4Mb cache (or 6Mb for WT), 100000 byte values, limit to 10000 items.
# bigval - 512Mb cache, 100000 byte values, limit to 4000 items.
#
# It runs the op that is in force at the time it finds the db to run.
# So, an example would be:
# run.sh wt lvl bdb
# run.sh small wt lvl bdb
# run.sh bigval wt lvl
# run.sh small wt lvl bdb big wt lvl bdb
#
mb128=134217728
mb512=536870912
benchargs="--cache_size=$mb128"
mb4="4194304"
mb4wt="6537216"
smallrun="no"
op="big"
fdir="./DATA"
while :
	do case "$1" in
	small)
		smallrun="yes"
		benchargs=""
		op="small"
		shift;;
	big|large)
		smallrun="no"
		benchargs="--cache_size=$mb128"
		op="big"
		shift;;
	bigval)
		smallrun="no"
		benchargs="--cache_size=$mb512 --value_size=100000 --num=4000"
		op="bigval"
		shift;;
	val|smval)
		smallrun="yes"
		benchargs="--value_size=100000 --num=10000"
		op="val"
		shift;;
	bdb)
		fname=$fdir/$op.$$.bdbsymas
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4"
		}
		if test -e ./db_bench_bdb; then
			time env "$bdblib_path" ./db_bench_bdb $benchargs > $fname
		else
			echo "Skipping, db_bench_bdb is not built."
		fi
		shift;;
	ldb|leveldb|lvldb|lvl)
		fname=$fdir/$op.$$.lvl
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4"
		}
		if test -e ./db_bench; then
			time ./db_bench $benchargs > $fname
		else
			echo "Skipping, db_bench is not built."
		fi
		shift;;
	ldbs|leveldbs|lvldbs|lvls)
		fname=$fdir/$op.$$.lvlsymas
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4"
		}
		if test -e ./db_bench_leveldb; then
			time ./db_bench_leveldb $benchargs > $fname
		else
			echo "Skipping, db_bench_leveldb is not built."
		fi
		shift;;
	wt|wiredtiger)
		fname=$fdir/$op.$$.wt
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4wt"
		}
		if test -e ./db_bench_wiredtiger; then
			test_compress
			time env "$lib_path" ./db_bench_wiredtiger $benchargs > $fname
		else
			echo "Skipping, db_bench_wiredtiger is not built."
		fi
		shift;;
	wts|wtsymas)
		fname=$fdir/$op.$$.wtsymas
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4wt"
		}
		if test -e ./db_bench_wtsymas; then
			time env "$lib_path" ./db_bench_wtsymas $benchargs > $fname
		else
			echo "Skipping, db_bench_wtsymas is not built."
		fi
		shift;;
	*)
		break;;
	esac
done
