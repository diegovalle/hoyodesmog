if (!require(devtools, quietly = TRUE)) {
  install.packages("devtools", repos="http://cran.rstudio.com")
}
if (!require("aire.zmvm", quietly = TRUE)) {
  devtools::install_github('diegovalle/aire.zmvm')
  require("aire.zmvm")
}
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
                                                    repos="http://cran.rstudio.com")
for(p in packages.to.load)
  suppressPackageStartupMessages( stopifnot(
    require(p, quietly=TRUE,
            character.only=TRUE)))


source(file.path("src", "heatmap.R"))