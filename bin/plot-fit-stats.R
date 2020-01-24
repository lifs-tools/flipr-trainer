#!/usr/bin/Rscript
library("readr")
library("tidyr")
library("ggplot2")
library("viridis")
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
  statistic = col_double(),
  p.value = col_double(),
  isNormal = col_logical(),
  resSSq = col_double(),
  meanResSSq = col_double()
)

fit_stats <- read_tsv(parametersFile,  col_types = colspec)
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
)
data$fragadd <- paste(data$fragment, data$adduct, sep = " ")
data$calculatedMass <- as.numeric(data$calculatedMass)
data$fragadd <-
  factor(data$fragadd, levels = unique(data[order(data$calculatedMass),]$fragadd))
plot <- ggplot2::ggplot(data = data) +
  ggplot2::geom_point(ggplot2::aes(x=meanResSSq, y=species, shape=`foundMassRange[ppm]`, color=calculatedMass), size=2, data, show.legend = TRUE) +
  ggplot2::theme_bw(base_size = 12, base_family = 'Helvetica') +
#  ggplot2::theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) + 
  ggplot2::labs(title = "Species vs. estimated mean residual sum-of-squares", shape = 'Mass Range [ppm]', col = 'm/z') +
  ggplot2::ylab("Species") +
  ggplot2::xlab(expression(paste(log[10], bar(mu)," Res. SSq",sep = " "))) +
#  ggplot2::coord_trans(x = "log10") +
  ggplot2::scale_x_log10(limits=c(1e-07,1e-0)) + 
  ggplot2::scale_shape_manual(values=c(3, 5)) +
#  ggplot2::scale_color_gradient()
  scale_color_viridis(discrete=FALSE) 
print(paste("Saving output to", opt$outputDir)) 
setwd(opt$outputDir)
plotname <- paste0(baseFileName, ".",  plotFormat)
print(paste0("Saving plot to ", plotname))
ggsave(filename = plotname, plot, width = 210, height = 297, units = "mm")
