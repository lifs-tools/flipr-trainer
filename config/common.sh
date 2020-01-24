#!/bin/bash
sp="/-\|"
dotpid=
rundots() { ( trap 'exit 0' SIGUSR1; echo -n ' '; while : ; do printf "\b${sp:i++%${#sp}:1}" >&2; sleep 0.2; done) &  dotpid=$!; }
stopdots() { kill -USR1 $dotpid; wait $dotpid; trap EXIT; }
startdots() { rundots; trap "stopdots" EXIT; return 0; }

NCORES=$(lscpu -p | egrep -v '^#' | wc -l)
echo "$NCORES logical cores available!"
#TSTAMP=$(date +"%Y-%m-%dT%H:%M")
#TSTAMP=$(date --rfc-3339=seconds | sed -e "s/ /_/g")
NTHREADS=$((NCORES / 2))
echo "Running on $NTHREADS threads"
CMD="java -jar lib/flipr-transition-extractor-1.0.9.jar"
echo "Using $CMD"
