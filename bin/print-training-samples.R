#!/usr/bin/Rscript
library("readr")
library("tidyr")
library("dplyr")
library("optparse")
library("broom")
options(show.error.locations = TRUE)
# specify our desired options in a list
# by default OptionParser will add an help option equivalent to
# make_option(c("-h", "--help"), action="store_true", default=FALSE,
# help="Show this help message and exit")
option_list <- list(
  make_option("--parametersFile",
              help = "The parameters file (tsv) to use as input for plotting [default \"%default\"]"),
  make_option("--outputDir", default = getwd(),
              help = "The output directory to store plots in [default \"%default\"]"),
  make_option("--plotFormat", default = "png",
              help = "The file format used for plots (png, pdf, svg) [default \"%default\"]")
)
# get command line options, if help option encountered print help and exit,
# otherwise if options not found on command line then set defaults,
opt <- optparse::parse_args(OptionParser(option_list = option_list))
plotFormat <- opt$plotFormat
parametersFile <- opt$parametersFile
if (is.null(parametersFile)) {
  optparse::print_help(OptionParser(option_list = option_list))
  stop("No input!")
}

filename <- basename(parametersFile)
baseFileName <- gsub(pattern = "\\.tsv$", "", basename(filename))

colspec <- cols(.default = col_character(), fragment=col_character(), instrument = col_character(), localDateTimeCreated = col_character(), origin=col_character(), combinationId=col_character(), polarity=col_character())
training_samples <- read_tsv(parametersFile,  col_types = colspec)
summary_data <- training_samples %>% group_by(combinationId, precursorCollisionEnergy) %>% summarise(samples=n(), minCe=min(precursorCollisionEnergy), maxCe=max(precursorCollisionEnergy))
print(paste("Saving output to", opt$outputDir)) 
setwd(opt$outputDir)
summary_table <- glance(summary(summary_data$samples))
write_tsv(summary_table, "number-of-training-samples.tsv")
min_ce <- min(summary_data$minCe)
max_ce <- max(summary_data$maxCe)
write_tsv(tibble(minCe=min_ce,maxCe=max_ce), "ce-range.tsv")
