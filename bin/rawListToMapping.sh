#!/bin/bash
cat QExHF_RAWlist_PL_GL_Ch.csv | cut -f4,5,6,7,8,9,10 > pl-gl-ch-mapping-qex-hf.tsv
cat QTof_measurements.csv | cut -f4,5,6,7,8,9,10 > lipid-mapping-qtof.tsv 
