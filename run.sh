#!/bin/sh

# Run Wired Tiger Level DB benchmark.
# Assumes that a pre-built Wired Tiger library exists in ../wiredtiger.
# Assumes that the Wired Tiger build is shared, not static.

WT_PATH="../wiredtiger/build_posix"
SNAPPY_PATH="ext/compressors/snappy_compress/.libs"

if [ ! -e "$WT_PATH/$SNAPPY_PATH/snappy_compress.so" ]; then
	echo "Snappy compression not included in Wired Tiger."
	exit 1
fi

if [ `uname` == "Darwin" ]; then
	lib_path="DYLD_LIBRARY_PATH=$WT_PATH/.libs:$WT_PATH/$SNAPPY_PATH"
else
	lib_path="LD_LIBRARY_PATH=$WT_PATH/.libs:$WT_PATH/$SNAPPY_PATH"
fi


env "$lib_path" ./db_bench_wiredtiger --cache_size=104857600
