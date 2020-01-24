#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Please supply the machine to run FIP for as the first argument! (qtof or qex-hf)"
    exit 1
fi
if [ -z "$1" ]; then
    echo "Please supply the machine to run FIP for as the first argument! (qtof or qex-hf)"
    exit 1
fi

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/config/common.sh"

echo "Preparing concatenated transition list from *.tsv files in '$DIR/transitions'"
mkdir -p $DIR/tmp
rm -r $DIR/tmp/*
$DIR/bin/concat-transitions.sh transitions/ $DIR/tmp/all-transitions.tsv
cp $DIR/tmp/all-transitions.tsv $DIR

INSTANCE="all"
MACHINE="$1"
TRANSITIONS="$INSTANCE-transitions.tsv"
MAPPINGS="$INSTANCE-mapping-$MACHINE.tsv"
OUT="results/$MACHINE/"
CFG="config/$MACHINE.properties"
RCFG="config/$MACHINE.R"
CONCAT_IN="$OUT/$INSTANCE-transitions/"
FLIPR_PATH=$(R -e "system.file('exec','flipr.R',package='flipr');" | egrep -oe "(/[A-Za-z0-9_.-]+)+")
if [ -z $FLIPR_PATH ]; then
echo "Please make sure that the flipr package has been installed on your system!"
echo "Consult https://gitlab.isas.de/hoffmann/flipr for installation instructions!"
exit 1
fi

echo "Using flipr script at $FLIPR_PATH"

mkdir -p $CONCAT_IN
echo "Preparing concatenated file with measurement file to transition mappings from '$DIR/mappings/$MACHINE' using '$DIR/$MACHINE-selected.txt' as Group filter."
$DIR/bin/concat-mappings.sh mappings/$MACHINE/ $DIR/tmp/$INSTANCE-mapping-$MACHINE.tsv.tmp $DIR/config/$MACHINE-selected.txt && cat $DIR/tmp/$INSTANCE-mapping-$MACHINE.tsv.tmp | cut -f4,5,6,7,8,9,10 > $DIR/tmp/$INSTANCE-mapping-$MACHINE.tsv

cp $DIR/tmp/$INSTANCE-mapping-$MACHINE.tsv $DIR

echo "Running Transition Extractor and flipR with transition file '$TRANSITIONS' and mapping file '$MAPPINGS' with output in '$OUT'"
echo "Capturing log output in $CONCAT_IN/$INSTANCE-$MACHINE.log"
startdots
$CMD -i $TRANSITIONS -j $MAPPINGS -o $OUT -t $NTHREADS -c $CFG -x $RCFG --flipr=$FLIPR_PATH > $CONCAT_IN/$INSTANCE-$MACHINE.log 2>&1 && $CMD -p $CONCAT_IN >> $CONCAT_IN/$INSTANCE-$MACHINE.log 2>&1
find $CONCAT_IN -name "*.out" | xargs grep -C2 -E "Error" > "$CONCAT_IN/$INSTANCE-transitions-$MACHINE.errors"
NERR=$(egrep -e ".*-run\.out:" "$CONCAT_IN/$INSTANCE-transitions-$MACHINE.errors" | wc -l)
stopdots
echo ""
if [ $NERR -eq 0 ]; then
  echo "All TrEX/FIP instances terminated successfully!"
else
  echo "TrEX/FIP failed for $NERR instances. Please check '$CONCAT_IN/$INSTANCE-transitions-$MACHINE.errors' for details!"
fi
echo "Plotting Parameter Stats!"

$DIR/create-summary-plots.sh "$1"

rm $CONCAT_IN/$INSTANCE-$MACHINE.adoc
MACHINE_LONG=$MACHINE
echo "Creating supplementary document for $MACHINE_LONG"
if [ $MACHINE == "qex-hf" ]; then
  MACHINE_LONG="Thermo Scientific Q Exactive HF [MS:1002523]"
elif [ $MACHINE == "qtof" ]; then
  MACHINE_LONG="Agilent 6545 Q-TOF LC/MS [MS:1002791]"
fi
$DIR/create-docx.sh $CONCAT_IN $CONCAT_IN/$INSTANCE-$MACHINE.adoc "$MACHINE_LONG"
