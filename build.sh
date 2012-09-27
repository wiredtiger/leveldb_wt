#!/bin/sh
# Build Wired Tiger Level DB benchmark.
# Assumes that a pre-built Wired Tiger library exists in ../wiredtiger.

WT_PATH="../wiredtiger/build_posix"
SNAPPY_PATH="ext/compressors/snappy_compress/.libs"

make && make db_bench
env LDFLAGS="-L$WT_PATH/.libs" CXXFLAGS="-I$WT_PATH" make db_bench_wiredtiger

