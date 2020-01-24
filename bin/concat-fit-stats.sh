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
if [ -e "$2" ]; then
    echo "File $2 exists! Please rename or delete it if you want to recreate it!"
else
    find $1 -name "*[POSITIVE|NEGATIVE]-residuals-normality.tsv" -exec awk 'FNR>1 || NR==1' {} + >> $2
    ECODE=$?
    if [ ! $ECODE -eq 0 ]; then
      echo "Concatenation of $1 into $2 returned with exit code $ECODE"
      exit $ECODE
    fi
fi
#if [ -e "$2" ]; then
#    Rscript plot-parameter-ranges.R --parametersFile=$2
#else 
#    echo "Cannot create plots. File $2 does not exist!"
#    exit 1
#fi
