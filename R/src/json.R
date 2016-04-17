

zpad <- function(x) str_pad(x, 2, "left", "0")

get_data_month <- function(pollutant) {
  current_datetime <- Sys.time()
  current_datetime <- with_tz(current_datetime, "America/Mexico_City")
  
  current_month <- month(current_datetime)
  last_month <- 0
  if(day(current_datetime) < 9) {
    if(current_month == 1) {
      last_month <- 12
    } else {
      last_month <- current_month - 1
    }
  }
  
  df <- get_station_single_month(pollutant = pollutant, 
                               year =  year(current_datetime),
                               month = zpad(current_month))
  if(last_month != 0) {
    if(last_month == 12) {
      year_to_download <-  year(current_datetime)-1
    } else {
      year_to_download <-  year(current_datetime)
    }
    df <- rbind(df,  get_station_single_month(pollutant = pollutant, 
                                            year =  year_to_download,
                                            month = zpad(last_month)))
  }
  #df$imecas <-  convert_to_imeca(df$value, "O3")
  # The time is given in hours with no DST
  # GMT has no DST
  df$datetime <- strptime(str_c(df$date, " ", df$hour),
                          "%Y-%m-%d %H", tz = "GMT+6") %>% as.POSIXct()
  # Convert to MXC time
  df$datetime_mxc <- as.POSIXct(format(df$datetime, tz="America/Mexico_City", usetz=TRUE))
  
  df <- df %>%
    group_by(station_code) %>%
    mutate(max = ifelse(all(is.na(tail(value, 6))),
                        NA_real_,
                        max(tail(value,6), na.rm = TRUE))) %>%
    ungroup() %>%
    arrange(-max, station_code, date, hour) %>%
    select(-max)
}


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
  
  sink(str_c("../web/data/station_codes_", tolower(pollutant), ".json"))
  print(toJSON(unique(o3$station_code), na = "null"))
  sink(file = NULL)
  
  sink(str_c("../web/data/station_names_", tolower(pollutant), ".json"))
  print(toJSON(stations[ ,c("station_code", "station_name")]))
  sink(file = NULL)
  
  sink(str_c("../web/data/stations_", tolower(pollutant), ".json"))
  print(toJSON(ll, na = "null"))
  sink(file = NULL)
}

write_json <- function(file_name, stuff, ...) {
  writeLines(toJSON(stuff, ...), file_name)
  
}
