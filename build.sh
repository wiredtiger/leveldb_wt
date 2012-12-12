#!/bin/sh
# Build Wired Tiger Level DB benchmark.
# Assumes that a pre-built Wired Tiger library exists in ../wiredtiger.

WT_PATH="../wiredtiger/build_posix"
BDB_PATH="../../db-5.3.21/build_unix"
SNAPPY_PATH="ext/compressors/snappy/.libs"

make && make db_bench
env LDFLAGS="-L$WT_PATH/.libs" CXXFLAGS="-I$WT_PATH" make db_bench_wiredtiger

if test -f doc/bench/db_bench_bdb.cc; then
    env LDFLAGS="-L$BDB_PATH/.libs" CXXFLAGS="-I$BDB_PATH" make db_bench_bdb
fi

if test -f doc/bench/db_bench_leveldb.cc; then
    make db_bench_leveldb
fi
