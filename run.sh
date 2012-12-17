#!/bin/sh

# Run Wired Tiger Level DB benchmark.
# Assumes that a pre-built Wired Tiger library exists in ../wiredtiger.
# Assumes that the Wired Tiger build is shared, not static.
# but works if it is static.

WT_PATH="../wiredtiger/build_posix"
BASHO_PATH="../basho.leveldb"
BDB_PATH="../db-5.3.21/build_unix"
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
	basholib_path="DYLD_LIBRARY_PATH=$BASHO_PATH:"
	bdblib_path="DYLD_LIBRARY_PATH=$BDB_PATH/.libs:"
	levellib_path="DYLD_LIBRARY_PATH=.:"
	wtlib_path="DYLD_LIBRARY_PATH=$WT_PATH/.libs:$WT_PATH/$SNAPPY_PATH"
else
	basholib_path="LD_LIBRARY_PATH=$BASHO_PATH:"
	bdblib_path="LD_LIBRARY_PATH=$BDB_PATH/.libs:"
	levellib_path="LD_LIBRARY_PATH=.:"
	wtlib_path="LD_LIBRARY_PATH=$WT_PATH/.libs:$WT_PATH/$SNAPPY_PATH"
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
#
mb128=134217728
mb512=536870912
benchargs="--cache_size=$mb128"
mb4="4194304"
mb4wt="6537216"
smallrun="no"
op="big"
fdir="./DATA"
# The first arg may be the operation type.
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
	*)
		break;;
	esac
done

# Now that we have the operation to run, do so on all remaining DB types.
while :
	do case "$1" in
	basho)
		fname=$fdir/$op.$$.basho
		libp=$basholib_path
		prog=./db_bench_basho
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4"
		}
		shift;;
	bashos|bashosymas)
		fname=$fdir/$op.$$.bosymas
		libp=$basholib_path
		prog=./db_bench_bashosymas
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4"
		}
		shift;;
	bdb)
		fname=$fdir/$op.$$.bdbsymas
		libp=$bdblib_path
		prog=./db_bench_bdb
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4"
		}
		shift;;
	ldb|leveldb|lvldb|lvl)
		fname=$fdir/$op.$$.lvl
		libp=$levellib_path
		prog=./db_bench
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4"
		}
		shift;;
	ldbs|leveldbs|lvldbs|lvls)
		fname=$fdir/$op.$$.lvlsymas
		libp=$levellib_path
		prog=./db_bench_leveldb
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4"
		}
		shift;;
	wt|wiredtiger)
		fname=$fdir/$op.$$.wt
		libp=$wtlib_path
		prog=./db_bench_wiredtiger
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4wt"
		}
		test_compress
		shift;;
	wts|wtsymas)
		fname=$fdir/$op.$$.wtsymas
		libp=$wtlib_path
		prog=./db_bench_wtsymas
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4wt"
		}
		shift;;
	*)
		break;;
	esac
	# If we have a command to execute do so.
	if test -e $prog; then
		time env "$libp" $prog $benchargs > $fname
	else
		echo "Skipping, $prog is not built."
	fi
done
