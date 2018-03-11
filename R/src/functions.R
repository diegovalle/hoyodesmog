
recode_unit <- function(pollutant) {
  str_replace_all(pollutant, c("pm2" = "\u00B5g/m\u00B3", "so2" = "ppb", "co" = "ppm",
                               "nox" = "ppb", "no2"="ppb", "no"="ppb", "o3"="ppb",
                               "pm10"="\u00B5g/m\u00B3", "pm25"="\u00B5g/m\u00B3", "wsp"="m/s",
                               "wdr"="\u00B0",
                               "tmp"="\u00B0C", "rh"="%"))
}

recode_pollutant <- function(pollutant) {
  str_replace_all(pollutant, c("pm2" = "PM25", "so2" = "SO2", "co" = "CO",
                               "nox" = "NOX", "no2"="NO2", "no"="NO", "o3"="O3",
                               "pm10"="PM10", "pm25"="PM25", "wsp"="WSP", "wdr"="WDR",
                               "tmp"="TMP", "rh"="RH", "PM2.5"="PM25"))
}

get_month_data <- function(criterion, pollutant, year, month = "") {
  # if(pollutant == "pm25")
  #   pollutant <- "pm2"
  # base_url <- "http://www.aire.cdmx.gob.mx/estadisticas-consultas/concentraciones/respuesta.php?"
  # url <- str_c(base_url, "qtipo=", criterion, "&",
  #              "parametro=", pollutant, "&",
  #              "anio=", year, "&",
  #              "qmes=", month)
  # poll_table <- read_html(httr::GET(url,  httr::timeout(60)))
  # df <- html_table(html_nodes(poll_table, "table")[[1]], header = TRUE)
  
  pollutant = tolower(pollutant)
  df <- read.csv(str_c("airedata/",
                       pollutant, ".csv"))
  
  #names(df) <- df[1,]
  names(df)[1] <- "date"
  names(df) <- iconv(names(df), from="UTF-8", to="ASCII", sub="")
  names(df) <- str_replace_all(names(df), "\\s", "")
  if(!nrow(df) > 2)
    stop("something went wrong when downloading the data")
  #df <- df[2:nrow(df),]
  
  df[df == "nr"] <- NA
  df[,2:ncol(df)] <- apply(df[,2:ncol(df)], 2, as.numeric)
  # when the data is HORARIOS the second column corresponds to the hour
  if(criterion == "HORARIOS") {
    names(df)[2] <- "hour"
  }
  # The website messed up and changed the station_name of the Montecillo (Texcoco) station
  # to CHA instead of MON
  if("CHA" %in% names(df)) {
    if(!"MON" %in% names(df)) {
      names(df)[which(names(df) == "CHA")] <- "MON"
    }
  }
  
  #df$date <- as.character(fast_strptime(df$date, "%d-%m-%Y"))
  df$date <- str_c(str_sub(df$date, 7, 10), "-",
                   str_sub(df$date, 4, 5), "-",
                   str_sub(df$date, 1, 2))
  
  df$date <- as.Date(df$date)
  if(criterion != "HORARIOS") {
    val_cols <- base::setdiff(names(df), c("date"))
  } else {
    val_cols <- base::setdiff(names(df), c("date", "hour"))
  }
  df <- gather_(df, "station_code", "value", val_cols)
  df$station_code <- as.character(df$station_code)
  
  # print(evaluate_promise({recode(pollutant, '"pm2" = "\u00B5g/m\u00B3"; "so2" = "ppb"; "co" = "ppm";
  #                        "nox" = "ppb"; "no2"="ppb"; "no"="ppb"; "o3"="ppb";
  #                        "pm10"="\u00B5g/m\u00B3"; "pm25"="\u00B5g/m\u00B3"; "wsp"="m/s";
  #                        "wdr"="\u00B0";
  #                        "tmp"="\u00B0C"; "rh"="%"')}))
  df$unit <- recode_unit(pollutant)
  df$pollutant <- recode_pollutant(pollutant)
  
  # df$unit <- recode(pollutant, '"pm2" = "\u00B5g/m\u00B3"; "so2" = "ppb"; "co" = "ppm";
  #                        "nox" = "ppb"; "no2"="ppb"; "no"="ppb"; "o3"="ppb";
  #                        "pm10"="\u00B5g/m\u00B3"; "pm25"="\u00B5g/m\u00B3"; "wsp"="m/s";
  #                        "wdr"="\u00B0";
  #                        "tmp"="\u00B0C"; "rh"="%"')
  # df$pollutant <- recode(pollutant, '"pm2" = "PM25"; "so2" = "SO2"; "co" = "CO";
  #                        "nox" = "NOX"; "no2"="NO2"; "no"="NO"; "o3"="O3";
  #                        "pm10"="PM10"; "pm25"="PM25"; "wsp"="WSP"; "wdr"="WDR";
  #                        "tmp"="TMP"; "rh"="RH"')
  if(criterion != "HORARIOS") {
    df <- df[,c("date", "station_code", "pollutant", "unit", "value")]
  } else {
    df <- df[,c("date", "hour", "station_code", "pollutant", "unit", "value")]
  }
  
  as.data.frame(df)
  
  df$datetime <- strptime(str_c(df$date, " ", df$hour),
                          "%Y-%m-%d %H", tz = "GMT+6") %>% as.POSIXct()
  # Convert to MXC time
  df$datetime_mxc <- as.POSIXct(format(df$datetime, tz="America/Mexico_City", usetz=TRUE))
  # Because we're converting tables with lynx
  # sometimes there are extra rows at the bottom of the data.frame
  # (basically the header is repeated at the bottom of the table)
  df <- df[!is.na(df$date), ]
  df <- df %>%
    group_by(station_code) %>%
    arrange(station_code, date, hour) %>%
    mutate(max = ifelse(all(is.na(tail(value, 6))),
                        NA_real_,
                        max(tail(value,6), na.rm = TRUE))) %>%
    ungroup() %>%
    arrange(-max, station_code, date, hour) %>%
    select(-max)
}


zpad <- function(x) str_pad(x, 2, "left", "0")


create_json <- function(o3, pollutant) {

  
  ll <- list()
  i <- 1
  for(station_code2 in unique(o3$station_code)) {
    days <- 7
    df <- data.frame(value = filter(o3, station_code == station_code2)$value,
                     datetime = filter(o3, station_code == station_code2)$datetime_mxc,
                     station_code = filter(o3, station_code == station_code2)$station_code) %>% 
      tail(days*24) 
    df$station_code <- as.character(df$station_code)
    
    ll[[i]] <- left_join(df, stations[,c("station_code", "station_name")],
                         by = "station_code")
    i <- i + 1
  }
  
  sink(str_c("output/station_codes_", tolower(pollutant), ".json"))
  print(toJSON(unique(o3$station_code), na = "null"))
  sink(file = NULL)
  
  sink(str_c("output/station_names_", tolower(pollutant), ".json"))
  print(toJSON(stations[ ,c("station_code", "station_name")]))
  sink(file = NULL)
  
  sink(str_c("output/stations_", tolower(pollutant), ".json"))
  print(toJSON(ll, na = "null"))
  sink(file = NULL)
}

write_json <- function(file_name, stuff, ...) {
  writeLines(toJSON(stuff, ...), file_name)
  
}



zpad <- function(x) str_pad(x, 2, "left", "0")
