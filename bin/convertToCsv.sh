#!/bin/bash
for i in *.tsv; do tsv2csv.sh $i > dbimport/$i.csv; done

