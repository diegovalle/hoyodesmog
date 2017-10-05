


pollutant <- "SO2"
df <- get_month_data("HORARIOS", pollutant, "")
create_json(df, pollutant)