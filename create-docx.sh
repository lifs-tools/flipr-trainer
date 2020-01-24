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
if [ -z "$3" ]; then 
    echo "Please supply an MS platform name, e.g. 'Thermo QExactive HF'!"
    exit 1
fi 
echo "Creating asciidoc"
./create-docx.groovy -d $1 -o "$2" -title "FLIPR Results" -p "$3"
ECODE=$?
if [ ! $ECODE -eq 0 ]; then
  echo "Document creation with asciidoc in $1 into $2 returned with exit code $ECODE"
  exit $ECODE
fi
echo "Done!"
