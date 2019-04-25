line=as.character(Sys.time())
#write(line,file="time.txt",append=TRUE)


write_json <- function(file_name, stuff, dataframe = NULL) {
  writeLines(toJSON(stuff, dataframe = dataframe), file_name)
  
}

get_grid <- function(df) {
  df <- left_join(df, stations, by = "station_code")
  df <- df[!is.na(df$value) & !is.na(df$lat) & !is.na(df$lon),]
  geog <- df[,c("lat", "lon", "value")]
  coordinates(geog) <- ~lon+lat
  
  pixels = 100
  geog.grd <- expand.grid(x=seq((min(coordinates(geog)[,1])-.1),
                                (max(coordinates(geog)[,1])+.1),
                                length.out=pixels),
                          y=seq((min(coordinates(geog)[,2])-.1),
                                (max(coordinates(geog)[,2])+.1),
                                length.out=pixels))
  
  grd.pts <- SpatialPixels(SpatialPoints((geog.grd)))
  as(grd.pts, "SpatialGrid")
}

heatmap <- function(df, grid){
  if(nrow(df) == 0){
    return(data.frame(var1.pred = NA, var1.var = NA, lon = NA, lat = NA))
  }
  
  df <- left_join(df, stations, by = "station_code")
  df <- df[!is.na(df$value) & !is.na(df$lat) & !is.na(df$lon),]
  df <- df[,c("lat", "lon", "value")]
  coordinates(df) <- ~lon+lat
  df.idw <- idw(value ~ 1, df, grid, idp = 2, debug.level = 0)
  
  idw = as.data.frame(df.idw)
  names(idw) <- c("var1.pred", "var1.var", "lon", "lat")

  idw
}



merge_latest <- function(df, mxc, pollut) {
  mxc <- subset(mxc, pollutant == pollut)
  for(station_code in mxc$station_code) {
    idx <- which(station_code == mxc$station_code)
    if(idx)
      df$value[which(station_code == df$station_code)] <- mxc$value[idx]
  }
  df[!is.na(df$value),]
}


get_data_roll <- function(pollutant, mxc, ave) {
  df <- get_month_data("HORARIOS", pollutant, "") %>% 
    group_by(station_code) %>%
    mutate(rollave = rollapply(value, ave,
                               function(x) {
                                 if(sum(is.na(x)) > ave / 4)
                                   return(NA)
                                 mean(x, na.rm = TRUE)},
                               fill = NA, align = "right")) %>%
    mutate(value = suppressWarnings(convert_to_imeca(rollave, pollutant))) %>%
    filter(row_number() == n())
  merge_latest(df, mxc, pollutant)
}

get_data_24 <- function(pollutant, mxc) {
  df <- get_month_data("HORARIOS", pollutant, "") %>% 
    group_by(station_code) %>%
    mutate(rollave = rollapply(value, 24,
                               function(x) {
                                 if(sum(is.na(x)) > 6)
                                   return(NA)
                                 mean(x, na.rm = TRUE)},
                               fill = NA, align = "right")) %>%
    mutate(value = suppressWarnings(convert_to_imeca(rollave, pollutant))) %>%
    filter(row_number() == n())
  
}

get_data_8 <- function(pollutant, mxc) {
  df <- get_month_data("HORARIOS", pollutant, "") %>% 
    group_by(station_code) %>%
    mutate(rollave = rollapply(value, 8,
                               function(x) {
                                 if(sum(is.na(x)) > 2)
                                   return(NA)
                                 mean(x, na.rm = TRUE)},
                               fill = NA, align = "right")) %>%
    mutate(value = suppressWarnings(convert_to_imeca(rollave, pollutant))) %>%
    filter(row_number() == n())
  merge_latest(df, mxc, pollutant)
}

get_data <- function(pollutant, mxc) {
  df <- get_month_data("HORARIOS", pollutant, "") %>% 
    group_by(station_code) %>%
    mutate(value = suppressWarnings(convert_to_imeca(value, pollutant))) %>%
    filter(row_number() == n() )
  merge_latest(df, mxc, pollutant)
}


mxc <- get_latest_imeca()
print(mxc$datetime[[1]])
mxc2 <- left_join(mxc, stations, by = "station_code")
mxc2 <- mxc2[!is.na(mxc2$value) & !is.na(mxc2$lat) & !is.na(mxc2$lon),]

try({
  if (max(mxc$value, na.rm = TRUE) >= 145) {
    max_idx <- which(mxc$value == max(mxc$value, na.rm = TRUE))
    SENDGRID_PASS <- Sys.getenv("SENDGRID_PASS")
    SENDGRID_USER <- Sys.getenv("SENDGRID_USER")
    EMAIL_ADDRESS <- Sys.getenv("EMAIL_ADDRESS")
    send.mail(from = "imeca@elcri.men",
              to = str_c("<", EMAIL_ADDRESS, ">"),
              subject = str_c("IMECA of ", mxc$value[max_idx]),
              body = str_c(mxc$station_code[max_idx], " - ",
                           mxc$municipio[max_idx]),
              smtp = list(host.name = "smtp.sendgrid.net", port = 465,
                          user.name = SENDGRID_USER,
                          passwd = SENDGRID_PASS,
                          ssl = TRUE),
              authenticate = TRUE,
              send = TRUE)
  }
})

grid <- get_grid(mxc)

if(all(mxc$pollutant == "03")) {
  idw <- heatmap(mxc, grid)
  idw$pollutant <- "O<sub>3</sub>"
  write_json("output/heatmap_data.json",
             idw[,c("var1.pred", "lon", "lat", "pollutant")], "values")
} else {
  pm10 <- heatmap(get_data_roll("PM10", mxc, 24), grid)
  pm2 <- heatmap(get_data_roll("PM2", mxc, 24), grid)
  o3 <- heatmap(get_data_roll("O3", mxc, 1), grid)
  co <- heatmap(get_data_roll("CO", mxc, 8), grid)
  no2 <- heatmap(get_data_roll("NO2", mxc, 1), grid)
  so2 <- heatmap(get_data_roll("SO2", mxc, 24), grid)
  
  idw <- pm10
  idw$var1.pred <- round(pmax(pm10$var1.pred, 
                              pm2$var1.pred, 
                              o3$var1.pred,
                              co$var1.pred,
                              no2$var1.pred,
                              so2$var1.pred, na.rm = TRUE))
  idw$pollutant <- apply(data.frame(pm10$var1.pred,
                                    pm2$var1.pred,
                                    o3$var1.pred,
                                    co$var1.pred,
                                    no2$var1.pred,
                                    so2$var1.pred),
        1, function(x) {
          switch(which.max(x),
                 "1" = "PM<sub>10</sub>",
                 "2" = "PM<sub>2.5</sub>",
                 "3" = "O<sub>3</sub>",
                 "4" = "CO",
                 "5" = "NO<sub>2</sub>",
                 "6" = "SO<sub>2</sub>"
          )
        })
  write_json("output/heatmap_data.json",
             idw[,c("var1.pred", "lon", "lat", "pollutant")], "values")
  
}

write_json("output/heatmap_stations.json",
           mxc2)
# 
# idw$lon[1] - idw$lon[2]
# idw$lat[1] - idw$lat[101]
# idw$lon[1]
# idw$lat[1]
# 
# library(httr)
# PUT(str_c("https://hoyodesmog.firebaseio.com/pollution_heatmap/",
#            mxc$datetime[[1]],
#            "/.json"),
#      body = str_c('{"heatmap": ',
#                   toJSON(idw[,c("var1.pred", "pollutant")], 
#                          dataframe = "values"), 
#                   ',"side_pixels":', 100,
#                   ',"lon_start":', idw$lon[1],
#                   ',"lat_start":', idw$lat[1],
#                   ',"lon_diff":', idw$lon[1] - idw$lon[2],
#                   ',"lat_diff":', idw$lat[1] - idw$lat[101],
#                   ',"stations": ',
#                   toJSON(mxc2), 
#                   ',"datetime": "', mxc$datetime[[1]], '"}'))
# 
# 
