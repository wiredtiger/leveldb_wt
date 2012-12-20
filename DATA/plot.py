#!/usr/bin/python -tt

"""Take raw output from benchmark from local runs and create gnuplot
ready data.  If there are more than 2 files with any given suffix,
it tosses the high and the low values for each operation type and averages
the rest of them to get a single value.
Output file prefix is given, and output is outfile.readseq.gnu,
outfile.fillsync.gnu, etc
Run with 'addraw.py outfilepfx runfile1 runfile2...'
"""

from os import system
import os.path

import re
import sys

def parse_raw(rawfile):
    rawf = open(rawfile, 'r')
    rawdata = {}
    for line in rawf:
        words = line.split()
        # Create a dict of key: opname value: micros/op-number
        # Conveniently, the benchmark often runs the same operations
        # multiple times (i.e. to prime the cache) and we take only
        # the last value.
        if len(words) > 2 and words[1] == ':':
            rawdata[words[0]] = words[2]
    rawf.close()
    return rawdata


def getavg(rawdicts, rawnames):
    newdict = {}
    sec = 1000000
    #
    # Rawnames is a dict where the key is the suffix, like 'wt' and the
    # value is a list of all filenames with that suffix.
    #
    for ftype in rawnames:
        opsdict = {}
        flist = rawnames[ftype]
        #
        # Go through each op/value pair for each filename in there and
        # build up a list of one op: list of values from all files.
        #
        for fname in flist:
            rawfiledata = rawdicts[fname]
            for op in rawfiledata:
                if not op in opsdict:
                    opsdict[op] = []
                opsdict[op].append(rawfiledata[op])
        print opsdict
        opsavg = {}
        for ops in opsdict:
            # Now generate a single average value for each operation.
            vals = opsdict[ops]
            if len(vals) > 2:
                 # If we have enough samples remove the min and max.
                 vals.remove(min(vals))
                 vals.remove(max(vals))
            sum = 0.0
            for v in vals:
                 sum += float(v)
            val = format(round(float(sec) / (sum/len(vals))), '.0f')
            print 'Avg for ' + ftype + ' op: ' + ops + ':  ' + str(val)
            opsavg[ops] = val
        newdict[ftype] = opsavg
    return newdict

#
# Generate the gnuplot file.
#
def gen_gnuplot(opfx, dname, op, glist):
    fname = opfx + '.' + op + '.gnu'
    fd = open(fname, 'w+')
    fd.write('set title "LevelDB ' + op + ' Throughput"\n')
    fd.write('set terminal jpeg medium\n')
    jname = opfx + '.' + op + '.jpg'
    fd.write('set output "' + jname + '"\n')
    fd.write('set border 3 front linetype -1 linewidth 1.000\n')
    fd.write('set style data histogram\n')
    fd.write('set xlabel "DB Source"\n')
    fd.write('set ylabel "Ops/sec"\n')
    fd.write('set grid\n')
    fd.write('set boxwidth 0.95 relative\n')
    fd.write('set style fill transparent solid 0.5 noborder\n')
    fd.write('plot "' + dname + '" u 2:xticlabels(1) w boxes lc rgb"green" notitle\n')
    fd.close
    glist.append(fname)

def generate_data(rawdicts, rawnames, opfx):
    opsdict = getavg(rawdicts, rawnames)
    gnulist = []
    for ftype in opsdict:
        ops = opsdict[ftype]
        for op in ops:
            fname = opfx + '.' + op + '.res'
            exists = os.path.exists(fname)
            fd = open(fname, 'a')
            if not exists:
                fd.write('# DBSource\tOps/sec\n')
                gen_gnuplot(opfx, fname, op, gnulist)
            fd.write(ftype + '\t' + str(ops[op]) + '\n')
            fd.flush()
            fd.close

    print gnulist
    print 'Running gnuplot'
    for script in gnulist:
        cmd = ("gnuplot < %s" % script)
        print 'Executing ' + cmd
        system(cmd)

###
def main():
    numargs = len(sys.argv)
    if numargs < 3:
        print 'usage: ./' + sys.argv[0] + 'outfilepfx datafile1...'
        sys.exit(1)

    outfilepfx = sys.argv[1]
    d = 2
    rawdicts = {}
    rawnames = {}
    # File names should end with the runtype (i.e. big.PID.COUNT.wt)
    r = re.compile(r'.*\.(.+)$')
    while d < numargs:
        rawfile = sys.argv[d]
        # Create a dict containing this file's data.
        raw = parse_raw(rawfile)
        fmatch = r.search(rawfile)
        if fmatch:
            ftype = fmatch.group(1)
        else:
            print 'Bad file name ' + rawfile
            sys.exit(1)

        if not ftype in rawnames:
            rawnames[ftype] = []
        # Each file should only be there once.
        if not rawfile in rawdicts:
            rawnames[ftype].append(rawfile)
            rawdicts[rawfile] = raw
        d += 1
    generate_data(rawdicts, rawnames, outfilepfx)

    sys.exit(0)

if __name__ == '__main__':
    main()
