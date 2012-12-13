#!/bin/sh
# Build Wired Tiger Level DB benchmark.
# Assumes that a pre-built Wired Tiger library exists in ../wiredtiger.

WT_PATH="../wiredtiger/build_posix"
BDB_PATH="../../db-5.3.21/build_unix"
SNAPPY_PATH="ext/compressors/snappy/.libs"

make && make db_bench
echo "Making DB-specific benchmarks"
if test -f doc/bench/db_bench_wiredtiger.cc; then
    echo "Making SYMAS configured WT benchmark into db_bench_wtsymas"
    rm -f doc/bench/db_bench_wiredtiger.o
    env LDFLAGS="-L$WT_PATH/.libs" CXXFLAGS="-I$WT_PATH -DSYMAS_CONFIG" make db_bench_wiredtiger
    mv db_bench_wiredtiger db_bench_wtsymas
    rm -f doc/bench/db_bench_wiredtiger.o
    echo "Making standard WT benchmark"
    env LDFLAGS="-L$WT_PATH/.libs" CXXFLAGS="-I$WT_PATH" make db_bench_wiredtiger
fi

if test -f doc/bench/db_bench_bdb.cc; then
    echo "Making SYMAS configured BerkeleyDB benchmark"
    env LDFLAGS="-L$BDB_PATH/.libs" CXXFLAGS="-I$BDB_PATH" make db_bench_bdb
fi

if test -f doc/bench/db_bench_leveldb.cc; then
    echo "Making SYMAS configured LevelDB benchmark"
    make db_bench_leveldb
fi
