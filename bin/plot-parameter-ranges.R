#!/usr/bin/Rscript
library("readr")
library("tidyr")
library("ggplot2")
library("optparse")
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

colspec <- cols(
  combinationId = col_character(),
  fitFun = col_character(),
  term = col_character(),
  estimate = col_double(),
  std.error = col_double(),
  statistic = col_double(),
  p.value = col_double(),
  conf.low = col_double(),
  conf.high = col_double()
)
params <-
  readr::read_tsv(parametersFile, col_types = colspec)

print(paste("Saving output to", opt$outputDir)) 
setwd(opt$outputDir)

params_sep <- params %>% tidyr::separate(
  combinationId,
  c(
    "species",
    "precursorAdduct",
    "fragment",
    "adduct",
    "polarity",
    "calculatedMass",
    "ppmMassRange",
    "group"
  ),
  sep = "\\|",
  remove = FALSE
)

params_sep$species <- as.factor(params_sep$species)
params_sep$fragment <- as.factor(params_sep$fragment)
params_sep$adduct <- as.factor(params_sep$adduct)
params_sep$polarity <- as.factor(params_sep$polarity)
params_sep$calculatedMass <- as.numeric(params_sep$calculatedMass)
params_sep$ppmMassRange <- as.factor(params_sep$ppmMassRange)
params_sep$group <- as.factor(params_sep$group)

termSplit <- split(params_sep, params_sep$term)
lapply(termSplit, function(subset) {
  plot <-
    qplot(
      data = subset,
      x = species,
      y = estimate,
      group = fragment,
      color = species,
      shape = polarity,
      geom = "point",
      alpha = 0.3
    ) + facet_wrap(. ~ term + polarity, scales = "free_x", ncol = 2) +
    theme(legend.position = "none", axis.text.x = element_text(size = 6), axis.text.y = element_text(size = 6)) +
    coord_flip()

  ggsave(
    plot,
    filename = paste0(baseFileName, "-" ,unique(subset$term) , "-estimates.", opt$plotFormat),
    width = 8.27,
    height = 11.69
  )
})


plot <-
  qplot(
    data = params_sep,
    calculatedMass,
    p.value,
    group = combinationId,
    color = term,
    geom = "point",
    alpha = 0.3
  ) + facet_wrap(. ~ term, scales = "free_y")

ggsave(
  plot,
  filename = paste0(baseFileName, "-pvalue.", opt$plotFormat),
  width = 11.69,
  height = 8.27
)

plot <-
  qplot(
    data = params_sep,
    calculatedMass,
    std.error,
    group = combinationId,
    color = term,
    geom = "point",
    alpha = 0.3
  ) + facet_wrap(. ~ term, scales = "free_y") + scale_y_log10()

ggsave(
  plot,
  filename = paste0(baseFileName, "-std-error.", opt$plotFormat),
  width = 11.69,
  height = 8.27
)
