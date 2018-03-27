#!/bin/bash

USAGE_STR="Usage: $(basename $0) [-t] [ directory ]"

fdir="."
testonly=0

if [ $# -ge 1 ] && [ "$1" = "-t" ]; then
    testonly=1
    shift
fi

if [ $# -ge 1 ]; then
   if [ ${1:0:1} != "-" ]; then
       fdir=$1
       shift
   else
       echo >&2 "$USAGE_STR"
       exit 1
    fi
fi

echo "searching for directories containing spaces under $fdir .."

find $fdir -depth -name "* *" -type d | \
while read p; do
    f=${p##*/}
    d=${p%/*}
    if [ $testonly -eq 0 ]; then
        echo mv "$p" "$d/${f// /_}"
        mv "$p" "$d/${f// /_}"
    else
        echo "found $p"
    fi
done

echo "done."

