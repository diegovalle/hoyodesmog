
pollutant <- "PM2"
df <- get_month_data("HORARIOS", pollutant, "")
# needs to be pm25 for the file name
pollutant <- "PM25"
create_json(df, pollutant)