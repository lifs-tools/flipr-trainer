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

INSTANCE="all"
MACHINE="$1"
OUT="results/$MACHINE/"
CONCAT_IN="$OUT/$INSTANCE-transitions/"

echo "Plotting Parameter Stats!"
rm $CONCAT_IN/all-parameters.tsv
$DIR/bin/concat-parameters.sh $CONCAT_IN $CONCAT_IN/all-parameters.tsv >> $CONCAT_IN/$INSTANCE-$MACHINE.log 2>&1
$DIR/bin/plot-parameter-ranges.R --parametersFile=$CONCAT_IN/all-parameters.tsv --outputDir=$OUT --plotFormat=png >> $CONCAT_IN/$INSTANCE-$MACHINE.log 2>&1
echo "Plotting Mean Sum-of-Squared Residuals Stats!"
rm $CONCAT_IN/all-fits-residuals-meanssq.tsv
$DIR/bin/concat-fit-stats.sh $CONCAT_IN $CONCAT_IN/all-fits-residuals-meanssq.tsv >> $CONCAT_IN/$INSTANCE-$MACHINE.log 2>&1
$DIR/bin/plot-fit-stats.R --parametersFile=$CONCAT_IN/all-fits-residuals-meanssq.tsv --outputDir=$OUT --plotFormat=png >> $CONCAT_IN/$INSTANCE-$MACHINE.log 2>&1
echo "Plotting Residuals Stats!"
rm $CONCAT_IN/all-fits-residuals.tsv
$DIR/bin/concat-prediction-residuals.sh $CONCAT_IN $CONCAT_IN/all-fits-residuals.tsv >> $CONCAT_IN/$INSTANCE-$MACHINE.log 2>&1
$DIR/bin/plot-residual-stats.R --parametersFile=$CONCAT_IN/all-fits-residuals.tsv --outputDir=$OUT --plotFormat=png >> $CONCAT_IN/$INSTANCE-$MACHINE.log 2>&1
echo "Plotting Fit Data Stats!"
rm $CONCAT_IN/all-fits-data.tsv
$DIR/bin/concat-data-for-fit.sh $CONCAT_IN $CONCAT_IN/all-fits-data.tsv >> $CONCAT_IN/$INSTANCE-$MACHINE.log 2>&1
$DIR/bin/print-training-samples.R --parametersFile=$CONCAT_IN/all-fits-data.tsv --outputDir=$OUT --plotFormat=png >> $CONCAT_IN/$INSTANCE-$MACHINE.log 2>&1

rm $CONCAT_IN/$INSTANCE-$MACHINE.adoc
MACHINE_LONG=$MACHINE
echo "Creating supplementary document for $MACHINE_LONG"
if [ $MACHINE == "qex-hf" ]; then
  MACHINE_LONG="Thermo Scientific Q Exactive HF [MS:1002523]"
elif [ $MACHINE == "qtof" ]; then
  MACHINE_LONG="Agilent 6545 Q-TOF LC/MS [MS:1002791]"
fi
$DIR/create-docx.sh $CONCAT_IN $CONCAT_IN/$INSTANCE-$MACHINE.adoc "$MACHINE_LONG"

