fileName <- "timestamp_tmp.json"
pollutant <- "TMP"

if(file.exists(fileName)) {
  timestamp <- fromJSON(fileName, flatten=TRUE)
  df <- get_data_month(pollutant)
  print(max(df$datetime_mxc))
  
  if(max(df$datetime_mxc) > timestamp ) {
    create_json(df, pollutant)
    write_json(fileName, max(df$datetime_mxc))
  } else {
    print("no new data")
  }
  
} else {
  df <- get_data_month(pollutant)
  create_json(df, pollutant)
  
  write_json(fileName, max(df$datetime))
}