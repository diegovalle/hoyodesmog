if (!require(devtools, quietly = TRUE)) {
  install.packages("devtools", repos="https://mran.revolutionanalytics.com/snapshot/2017-10-03")
}
if (!require("aire.zmvm", quietly = TRUE)) {
  devtools::install_github('diegovalle/aire.zmvm')
  require("aire.zmvm")
}
# R CMD javareconf -e
packages.to.load <- c("phylin",
                      "viridis",
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
                      "mailR",
                      "XML",
                      "zoo",
                      "tidyr")
packages.not.installed <- setdiff(packages.to.load, installed.packages()[,"Package"])
if(length(packages.not.installed)) install.packages(packages.not.installed,
                                                    repos="https://mran.revolutionanalytics.com/snapshot/2017-10-03")
for(p in packages.to.load)
  suppressPackageStartupMessages( stopifnot(
    require(p, quietly=TRUE,
            character.only=TRUE)))

source(file.path("src", "functions.R"))

cat("\n\nheatmap.R")
source(file.path("src", "heatmap.R"))

cat("\n\nwsp_heatmap.R")
source(file.path("src", "wsp_heatmap.R"))

cat("\n\nwdr_heatmap.R")
source(file.path("src", "wdr_heatmap.R"))

cat("\n\ntemp_heatmap.R")
source(file.path("src", "temp_heatmap.R"))


cat("\n\njson-o3.R")
source(file.path("src", "json-o3.R"))

cat("\n\njson-pm10.R")
source(file.path("src", "json-pm10.R"))

cat("\n\njson-no2.R")
source(file.path("src", "json-no2.R"))

cat("\n\njson-so2.R")
source(file.path("src", "json-so2.R"))

cat("\n\njson-co.R")
source(file.path("src", "json-co.R"))

cat("\n\njson-pm25.R")
source(file.path("src", "json-pm25.R"))

cat("\n\njson-nox.R")
source(file.path("src", "json-nox.R"))

cat("\n\njson-tmp.R")
source(file.path("src", "json-tmp.R"))

