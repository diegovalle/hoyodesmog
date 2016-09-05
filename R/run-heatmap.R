if (!require(devtools, quietly = TRUE)) {
  install.packages("devtools", repos="https://mran.revolutionanalytics.com/snapshot/2016-09-03")
}
if (!require("aire.zmvm", quietly = TRUE)) {
  devtools::install_github('diegovalle/aire.zmvm')
  require("aire.zmvm")
}
# R CMD javareconf -e
packages.to.load <- c("viridis",
                      "dplyr",
                      "methods",
                      "jsonlite",
                      "gstat",
                      "sp",
                      "stringr",
                      "chron",
                      "ggmap",
                      "caTools",
                      "lubridate",
                      "mailR")
packages.not.installed <- setdiff(packages.to.load, installed.packages()[,"Package"])
if(length(packages.not.installed)) install.packages(packages.not.installed,
                                                    repos="https://mran.revolutionanalytics.com/snapshot/2016-09-03")
for(p in packages.to.load)
  suppressPackageStartupMessages( stopifnot(
    require(p, quietly=TRUE,
            character.only=TRUE)))


source(file.path("src", "heatmap.R"))
