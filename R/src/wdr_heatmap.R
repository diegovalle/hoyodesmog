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

# modified to work with degrees from phylin::idw
idw360 <-
  function(values, coords, grid, method="Shepard", p=2, R=2, N=15) {
   
    d.real <- real.dist(coords, grid)
    dimensions <- dim(d.real)
    
    methods <- c("Shepard", "Modified", "Neighbours")
    method <- agrep(method, methods)
    
    if (method == 1) {
      w <- 1/d.real**p
    } else if (method == 2) {
      w <- ((R-d.real) / (R*d.real))**p
    } else if (method == 3) {
      calcneighbours <- function(x, N) {
        x[order(x)][N:length(x)] <- Inf
        return(x)
      }
      newdist <- t(apply(d.real, 1, calcneighbours, N))
      w <- 1/newdist**p
    }
    
    # To allow the idw to act on points with same coordinate, rows are checked
    # for infinite weights. When found, points with Inf are 1 and all others 
    # have 0 weight
    for (i in 1:nrow(w)) {
      if (sum(is.infinite(w[i,])) > 0){
        w[i,!is.infinite(w[i,])] <- 0
        w[i,is.infinite(w[i,])] <- 1
      }
    }
    #browser()
    
    y <- (sin(values*(pi/180)))
    # Interpolation
    w.sum <- apply(w, 1, sum, na.rm=TRUE)
    wy <- w %*% diag(y)
    uy <- apply(wy/w.sum, 1, sum, na.rm=TRUE)
    
    x <- (cos(values*(pi/180)))
    # Interpolation
    w.sum <- apply(w, 1, sum, na.rm=TRUE)
    wx <- w %*% diag(x)
    ux <- apply(wx/w.sum, 1, sum, na.rm=TRUE)
    
    res <- atan2(uy, ux) * (180 / pi)
    res <- ifelse(res < 0, 360 + res, res)
    
    data.frame(Z = res)
  }


heatmap_wdr <- function(){
  geog.o3 <- df[,c("lat", "lon", "value")]
  coordinates(geog.o3) <- ~lon+lat
  #spplot(geog.o3)
  
  pixels = 100
  geog.grd <- expand.grid(x=seq((min(coordinates(geog.o3)[,1])-.1),
                                (max(coordinates(geog.o3)[,1])+.1),
                                length.out=pixels),
                          y=seq((min(coordinates(geog.o3)[,2])-.1),
                                (max(coordinates(geog.o3)[,2])+.1),
                                length.out=pixels))
  
  grd.pts <- SpatialPixels(SpatialPoints((geog.grd)))
  grd.pts <- as(grd.pts, "SpatialGrid")
  
  #plot(grd.pts, cex = 1.5, col = "grey")
  #points(geog.o3, pch = 1, col = "red", cex = 1)
  
  idwc <- idw360(df$value, df[,c("lon", "lat")], as.data.frame(grd.pts))
  #real.dist(as.matrix(df[,c("lon", "lat")]), as.matrix(as.data.frame(grd.pts)))
  geog.idw <- idw(value ~ 1, geog.o3, grd.pts, debug.level =0)
  
  #spplot(geog.idw["var1.pred"])
  temp <- as.data.frame(geog.idw)
  temp <- cbind(idwc, NA, temp[,c("x", "y")])
  names(temp)=c("var1.pred", "var1.var", "lon", "lat")
  coordinates(temp) <- ~lon+lat
  #spplot(temp["var1.pred"])
  #atan2( ((sin(340*(pi/180))+ sin(320*(pi/180)) ) / 3), 
  #       ((cos(340*(pi/180))+ cos(320*(pi/180)) ) / 3) ) * 180 / pi
  
  idw = as.data.frame(temp)
  names(idw) <- c("var1.pred", "var1.var", "lon", "lat")
  
  write_json("../web/data/wdr_data.json",
             idw[,c("var1.pred", "lon", "lat")], "values")
  write_json("../web/data/wdr_stations.json",
             df)
}

heatmap_wdr()

