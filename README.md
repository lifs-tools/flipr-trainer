# FLIPR Trainer - Execution Environment for flipR
This collection of scripts is the training harness for CE-dependent, relative fragment intensity prediction models for LipidCreator.
If you need support to set the harness up, please create a GitHub issue or contact us at https://lifs.isas.de/support 

This project uses [flipr](https://github.com/lifs-tools/flipr) and the [flipr-transition-extractor](https://github.com/lifs-tools/flipr-transition-extractor).

## Requirements

### Operating System
The code of flipr trainer has been developed and tested on Ubuntu Linux 16.04 and 18.04. It should work on other Linuxes as well, but you may have to adapt the following commands for package installation to fit to your distribution.

### Execution of the training
- Java JRE > 1.8
- SDKMAN 

```
curl -s "https://get.sdkman.io" | bash
sdk install groovy
```

### Generation of reports
- Asciidoctor + Fonts

```
sudo apt install asciidoctor fonts-liberation
```
    
- Asciidoctor-PDF

```
sudo gem install asciidoctor-pdf -pre
sudo gem install prawn --version 2.1.0
sudo gem install prawn-svg --version 0.26.0
sudo gem install prawn-templates --version 0.0.4
```

### Model training  

- R >=3.5, see https://www.r-project.org/ for installation instructions
- devtools package (to install packages from github)
- Viridis package (color scale used for global overview plots over all instances)
- flipR package (Requires R>=3.5, for model training and selection)
- all other dependencies should be installed automatically

```
install.packages(c("devtools","viridis"))
library(devtools)
devtools::install_github("lifs-tools/flipr")
```

## Running the model training

Please note that the model training has been tested under Ubuntu 18.04 Linux only.
You will need to download the mzML files from the MetaboLights studies [MTBLS1333](https://www.ebi.ac.uk/metabolights/MTBLS1333) (qex-hf) and [MTBLS1334](https://www.ebi.ac.uk/metabolights/MTBLS1334) (qtof) to the respective measurements folders. E.g. `measurements/QExHF03` for the MTBLS1333 data, and `measurements/QTof` folder for the MTBLS1334 data.

To run the model training for one of the two platforms (termed `INSTANCE`), proceed as follows:

```
./run-fip.sh <INSTANCE>
```

where `<INSTANCE>` can be either `qex-hf` or `qtof`. 
This will also create overview plots for all trained models and the supplementary material pdf file with selected plots on the model performance for each molecule and group combination.

## Configuration

### General
The `config` folder contains a `<INSTANCE>.properties` file and an `<INSTANCE>.R` which set common properties for the model training with flipR and for the optimization bounds. The file `common.sh` defines common functions and BASH variables used by the other scripts. The `NTHREADS` will be set to half of the number of logical CPU cores available on your system. You can also set it lower, if you want to. 
The file also defines the command that runs the transition extractor on the mzML files, which in turn executes flipR (`CMD`). 

### Mapping measurements to transitions, configuration of PPM extraction
The `mappings` folder contains subfolders for each `<INSTANCE>`, e.g. `qex-hf`. This folder may contain multiple `.tsv` files with the following structure:

```
FileId	Mode	Name	Instrument	MoleculeGroup	PrecursorName	PrecursorAdduct	PPMS	File	Group	Date
QExHF03_NM_0000125	HCDoptimization_NegMode_2min_30K	PGF2alpha{d4}	MS:1002523	PGF2alpha	PGF2alpha{d4}	[M-H]1-	5|10	measurements/QExHF03/QExHF03_NM_0000125.mzML	125	Jul-27-2018
```

Each line represents one measurement. The line maps a file id, the molecule name, instrument cv term, precursor name, adduct, and the PPMS to use for signal extraction to the mzML file for that measurement. A Group can be provided to be able to disambiguate multiple measurements for the same molecule and similar conditions.

### Measurements 
Measurements are stored below the `measurements` folder. The name of the subfolders is arbitrary, but needs to be part of the path referencing the mzML files from the base directory (the directory containing this README file).

### Transitions
The transitions folder contains `.tsv` transition files that were created with LipidCreator in "development mode". To do so, you currently need to start LipidCreator.exe from the command line
- via cmd on Windows as `LipidCreator.exe dev`, or 
- via shell with `mono LipidCreator.exe dev` on Linux (this requires the latest mono version installed, tested with mono 6.8). 

This ensures that lipid PrecursorNames are written out in a format that can be mapped back into LipidCreator from the ce parameter file that flipR creates after the model training and selection process.

The MoleculeGroup, PrecursorName and PrecursorAdduct are joined with the columns in the mapping file to generate the list of transitions to extract from the mzML file.
