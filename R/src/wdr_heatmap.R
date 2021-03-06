write_json <- function(file_name, stuff, dataframe = NULL) {
  writeLines(toJSON(stuff, dataframe = dataframe), file_name)
  
}
pollutant="WDR"
df <- get_month_data("HORARIOS", pollutant, "")
df <- arrange(df, station_code, pollutant, date, hour)
df <- subset(df, date == max(df$date) & hour == tail(df, 1)$hour) 
df <- left_join(df, stations, by = "station_code")
df <- df[!is.na(df$value),]
df <- df[!is.na(df$lon),]
# The time is given in hours with no DST
# GMT has no DST
df$datetime <- strptime(str_c(df$date, " ", df$hour),
                        "%Y-%m-%d %H", tz = "GMT+6") %>% as.POSIXct()
# Convert to MXC time
df$datetime_mxc <- as.POSIXct(format(df$datetime, tz="America/Mexico_City", usetz=TRUE))

heatmap_wdr <- function(df){
  # coordinates of the wind measuring stations
  geog.o3 <- df[,c("lat", "lon", "value")]
  coordinates(geog.o3) <- ~lon+lat
  is.projected(geog.o3)
  proj4string(geog.o3) <- CRS("+proj=longlat +ellps=WGS84 +no_defs +towgs84=0,0,0")
  #spplot(geog.o3)
  
  # create a 100x100 grid based on the stations
  pixels = 100
  geog.grd <- expand.grid(x=seq((min(coordinates(geog.o3)[,1])-.1),
                                (max(coordinates(geog.o3)[,1])+.1),
                                length.out=pixels),
                          y=seq((min(coordinates(geog.o3)[,2])-.1),
                                (max(coordinates(geog.o3)[,2])+.1),
                                length.out=pixels))
  
  grd.pts <- SpatialPixels(SpatialPoints((geog.grd)))
  grd.pts <- as(grd.pts, "SpatialGrid")
  proj4string(grd.pts) <- CRS("+proj=longlat +ellps=WGS84 +no_defs +towgs84=0,0,0")
  
  #plot(grd.pts, cex = 1.5, col = "grey")
  #points(geog.o3, pch = 1, col = "red", cex = 1)
  
  # Inverse distance weighting
  idw <- idw360(geog.o3$value, geog.o3, grd.pts)
  idw <- cbind(idw, NA, as.data.frame(grd.pts))
  names(idw)=c("var1.pred", "var1.var", "lon", "lat") 
  #coordinates(temp) <- ~lon+lat
  #spplot(temp["var1.pred"])

  
  write_json("output/wdr_data.json",
             idw[,c("var1.pred", "lon", "lat")], "values")
  write_json("output/wdr_stations.json",
             df)
}

heatmap_wdr(df)

