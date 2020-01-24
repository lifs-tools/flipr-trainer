#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Please supply the subdirectory to process as the first argument!"
    exit 1
fi
if [ -z "$1" ]; then
    echo "Please supply the subdirectory to process as the first argument!"
    exit 1
fi
if [ -z "$2" ]; then
    echo "Please supply an output file name as the second argument!"
    exit 1
fi
# $3 echo "Please supply the group selection filter file as third argument!"
if [ -e "$2" ]; then
    echo "File $2 exists! Please rename or delete it if you want to recreate it!"
else
    find $1 -name "*.tsv" -exec awk 'FNR>1 || NR==1' {} + >> $2
    if [ ! -z "$3" ]; then
      echo "Filtering $2 with group ids from $3"
      fgrep -w -f $3 $2 >"$2.filtered"
      rm $2
      mv "$2.filtered" $2
    fi
    ECODE=$?
    if [ ! $ECODE -eq 0 ]; then
      echo "Concatenation of $1 into $2 returned with exit code $ECODE"
      exit $ECODE
    fi
fi
