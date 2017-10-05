pollutant <- "TMP"

df <- get_month_data("HORARIOS", pollutant, "")
create_json(df, pollutant)