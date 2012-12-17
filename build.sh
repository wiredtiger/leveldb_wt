#!/bin/sh
# Build Wired Tiger Level DB benchmark.
# Assumes that a pre-built Wired Tiger library exists in ../wiredtiger.

WT_PATH="../wiredtiger/build_posix"
BDB_PATH="../db-5.3.21/build_unix"
BASHO_PATH="../basho.leveldb"
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

if test -e $BASHO_PATH; then
    echo "Making Leveldb benchmark with Basho LevelDB library"
    #
    # We need to actually make the benchmarks in the Basho leveldb tree
    # in order for it to properly pick up all the right Basho files.
    #
    (cd $BASHO_PATH; make && make db_bench && make db_bench_leveldb)
    if test -e $BASHO_PATH/db_bench; then
        mv $BASHO_PATH/db_bench ./db_bench_basho
    else
	echo "db_bench did not build in Basho tree."
    fi
    if test -e $BASHO_PATH/db_bench_leveldb; then
        mv $BASHO_PATH/db_bench_leveldb ./db_bench_bashosymas
    else
	echo "db_bench_leveldb did not build in Basho tree."
    fi
fi

if test -f doc/bench/db_bench_bdb.cc; then
    echo "Making SYMAS configured BerkeleyDB benchmark"
    env LDFLAGS="-L$BDB_PATH/.libs" CXXFLAGS="-I$BDB_PATH" make db_bench_bdb
fi

if test -f doc/bench/db_bench_leveldb.cc; then
    echo "Making SYMAS configured LevelDB benchmark"
    make db_bench_leveldb
fi
