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
                      "lubridate")
packages.not.installed <- setdiff(packages.to.load, installed.packages()[,"Package"])
if(length(packages.not.installed)) install.packages(packages.not.installed,
                                                    repos="http://cran.rstudio.com")
for(p in packages.to.load)
  suppressPackageStartupMessages( stopifnot(
    require(p, quietly=TRUE,
            character.only=TRUE)))

try(
  source(file.path("src", "heatmap.R"))
)
try(
  source(file.path("src", "wsp_heatmap.R"))
)
try(
  source(file.path("src", "wdr_heatmap.R"))
)
try(
  source(file.path("src", "temp_heatmap.R"))
)
source(file.path("src", "json.R"))
try(
  source(file.path("src", "json-o3.R"))
)
try(
  source(file.path("src", "json-pm10.R"))
)
try(
  source(file.path("src", "json-no2.R"))
)
try(
  source(file.path("src", "json-so2.R"))
)
try(
  source(file.path("src", "json-co.R"))
)
try(
  source(file.path("src", "json-pm25.R"))
)
try(
  source(file.path("src", "json-nox.R"))
)
try(
  source(file.path("src", "json-tmp.R"))
)