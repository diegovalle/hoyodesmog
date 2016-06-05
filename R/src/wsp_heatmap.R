write_json <- function(file_name, stuff, dataframe = NULL) {
  writeLines(toJSON(stuff, dataframe = dataframe), file_name)
  
}

zpad <- function(x) str_pad(x, 2, "left", "0")

current_datetime <- Sys.time()
current_datetime <- with_tz(current_datetime, "America/Mexico_City")

current_month <- month(current_datetime)
last_month <- 0
if(day(current_datetime) < 2) {
  if(current_month == 1) {
    last_month <- 12
  } else {
    last_month <- current_month - 1
  }
}
pollutant="WSP"
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

df <- arrange(df, station_code, pollutant, date, hour)

df <- subset(df, date == max(df$date) & hour == tail(df, 1)$hour) 
df <- left_join(df, stations, by = "station_code")
df <- df[!is.na(df$value),]
# The time is given in hours with no DST
# GMT has no DST
df$datetime <- strptime(str_c(df$date, " ", df$hour),
                        "%Y-%m-%d %H", tz = "GMT+6") %>% as.POSIXct()
# Convert to MXC time
df$datetime_mxc <- as.POSIXct(format(df$datetime, tz="America/Mexico_City", usetz=TRUE))


heatmap_wsp <- function()  {
  geog.o3 <- df[,c("lat", "lon", "value")]
  coordinates(geog.o3) <- ~lon+lat
  #spplot(geog.o3)
  
  pixels = 100
  geog.grd <- expand.grid(x=seq((min(coordinates(geog.o3)[,1])-.15),
                                (max(coordinates(geog.o3)[,1])+.15),
                                length.out=pixels),
                          y=seq((min(coordinates(geog.o3)[,2])-.15),
                                (max(coordinates(geog.o3)[,2])+.15),
                                length.out=pixels))
  
  grd.pts <- SpatialPixels(SpatialPoints((geog.grd)))
  grd.pts <- as(grd.pts, "SpatialGrid")
  
  #plot(grd.pts, cex = 1.5, col = "grey")
  #points(geog.o3, pch = 1, col = "red", cex = 1)
  
  geog.idw <- idw(value ~ 1, geog.o3, grd.pts, idp = 6, debug.level =0)
  
  #spplot(geog.idw["var1.pred"])
  
  idw = as.data.frame(geog.idw)
  names(idw) <- c("var1.pred", "var1.var", "lon", "lat")
  
  # p <- qmplot(x, y, data = geog.grd, geom = "blank",
  #             maptype = "roadmap", source = "google")  +
  #   geom_tile(data = idw, aes(x = lon, y = lat, fill = var1.pred), alpha = .5) +
  #   scale_fill_viridis("IMECAS", limits = c(0,40), option = "inferno") +
  #   geom_point(data = mxc, aes(x = lon, y = lat, color = value), size = 2, alpha = .5) +
  #   scale_color_viridis("IMECAS",limits = c(0,40), option = "inferno") +
  #   ggtitle("Air quality in MXC")
  #ggsave("map.png", plot = p, width = 9, height = 8, dpi = 100)
  
  write_json("../web/data/wsp_data.json",
             idw[,c("var1.pred", "lon", "lat")], "values")
  write_json("../web/data/wsp_stations.json",
             df)
  write_json("timestamps/timestamp_wsp.json",
             df$datetime_mxc[[1]])
}


if(file.exists("timestamps/timestamp_wsp.json")) {
  timestamp <- fromJSON("timestamps/timestamp_wsp.json", flatten=TRUE)
  
  if(df$datetime_mxc[[1]] <= timestamp ) {
    print("no new data")
  } else {
    heatmap_wsp()
  
  } 
}else {
  heatmap_wsp()
}

