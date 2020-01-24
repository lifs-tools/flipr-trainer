#!/usr/bin/Rscript
library("readr")
library("tidyr")
library("dplyr")
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
  scanRelativeIntensity = col_double(),
  precursorCollisionEnergy = col_double(),
  X.weights. = col_double(),
  .fitted = col_double(),
  .resid = col_double()
)

fit_stats <- read_tsv(parametersFile, col_types = colspec)
#residuals plot of mean sum of squared residuals
data <- fit_stats %>% tidyr::separate(
  combinationId,
  c(
    "species",
    "precursorAdduct",
    "fragment",
    "adduct",
    "polarity",
    "calculatedMass",
    "foundMassRange[ppm]",
    "group"
  ),
  sep = "\\|",
  remove = FALSE
) %>% group_by(combinationId, species, `foundMassRange[ppm]`)

data_summary <- data %>% summarise(
  meanResid=mean(.resid, na.rm=T),
  sdev=sd(.resid, na.rm=FALSE),
  minResid=min(.resid, na.rm=T), 
  maxResid=max(.resid, na.rm=T)
)
print(paste("Saving output to", opt$outputDir)) 
setwd(opt$outputDir)
write_tsv(data_summary, path="all-fragments-residuals-summary.tsv")
pd <- position_dodge(0.5)
errorBarPlot <- ggplot2::ggplot(data = data_summary, ggplot2::aes(x=species, y=meanResid, colour=`foundMassRange[ppm]`)) + ggplot2::geom_errorbar(aes(ymin=meanResid-(3*sdev),ymax=meanResid+(3*sdev)), width=.1, position = pd) +
  geom_line(position = pd) + geom_point(position=pd) +
  ylim(-0.3,0.3) +
  ggplot2::theme_bw(base_size = 12, base_family = 'Helvetica') +
  ggplot2::labs(title = "Species vs. Avg. Residual (all fragments)", color = 'Target Mass Delta [ppm]') +
  ggplot2::xlab("Species") + ggplot2::ylab(expression(paste(mu,"(Residual) +/- 3", sigma, "(99,7%)", sep=" "))) + ggplot2::coord_flip()
ggsave(filename = paste0("all-fragments-residuals-summary",".",opt$plotFormat), errorBarPlot, width = 8.27, height = 11.69)
mmeanResid <- mean(data_summary$meanResid, na.rm=T)
msdev <- sd(data_summary$meanResid, na.rm=T)
mmd <- data.frame(mmeanResid=mmeanResid,msdev=msdev)
p<-ggplot(data, aes(x=.resid, color=`foundMassRange[ppm]`, fill=`foundMassRange[ppm]`)) +
  ggplot2::theme_bw(base_size = 12, base_family = 'Helvetica') +
  geom_density(alpha=0.5, position = "stack")+
  #facet_wrap(. ~ `foundMassRange[ppm]`, ncol = 2) +
  geom_vline(data=data_summary, aes(xintercept=meanResid, color=`foundMassRange[ppm]`),
             linetype="dashed") +
  geom_vline(data=mmd, aes(xintercept=mmeanResid-(3*msdev)), color='darkgrey') +
  geom_vline(data=mmd, aes(xintercept=mmeanResid+(3*msdev)), color='darkgrey') + 
  ggplot2::labs(title = "Density of Residuals (all fragments)", fill='Target Mass Delta [ppm]', color = 'Target Mass Delta [ppm]') +
  xlab("Residuals") + ylab("Density")
ggsave(filename = paste0("all-fragments-residuals-density",".",opt$plotFormat), p, width = 8.27, height = 11.69)
