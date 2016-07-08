
write_json <- function(file_name, stuff, dataframe = NULL) {
  writeLines(toJSON(stuff, dataframe = dataframe), file_name)
  
}

heatmap <- function(mxc){
  print(mxc$datetime[[1]])
  mxc <- left_join(mxc, stations, by = "station_code")
  mxc <- mxc[!is.na(mxc$value),]
  
  
  geog.o3 <- mxc[,c("lat", "lon", "value")]
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
  
  
  
  write_json("../web/data/heatmap_data.json",
             idw[,c("var1.pred", "lon", "lat")], "values")
  write_json("../web/data/heatmap_stations.json",
             mxc)
  write_json("timestamps/timestamp_heatmap.json",
             mxc$datetime[[1]])
  
  line=as.character(Sys.time())
  write(line,file="time.txt",append=TRUE)
}

mxc <- get_latest_data()
heatmap(mxc)

try({
  if(max(mxc$value, na.rm = TRUE) >= 151) {
    max_idx <- which(mxc$value == max(mxc$value, na.rm = TRUE))
    SENDGRID_PASS <- Sys.getenv("SENDGRID_PASS") 
    SENDGRID_USER <- Sys.getenv("SENDGRID_USER")
    EMAIL_ADDRESS <- Sys.getenv("EMAIL_ADDRESS")
    send.mail(from = EMAIL_ADDRESS,
              to = str_c("<", EMAIL_ADDRESS, ">"),
              subject = str_c("IMECA of ", mxc$value[max_idx]),
              body = str_c(mxc$station_code[max_idx], " - ", mxc$municipio[max_idx]),
              smtp = list(host.name = "smtp.sendgrid.net", port = 465, 
                          user.name = SENDGRID_USER, 
                          passwd = SENDGRID_PASS, 
                          ssl = TRUE),
              authenticate = TRUE,
              send = TRUE)
  }
})



# p <- qmplot(x, y, data = geog.grd, geom = "blank",
#             maptype = "roadmap", source = "google")  +
#   geom_tile(data = idw, aes(x = lon, y = lat, fill = var1.pred), alpha = .5) +
#   scale_fill_viridis("IMECAS", limits = c(0,200), option = "magma") +
#   geom_point(data = mxc, aes(x = lon, y = lat, color = quality), size = 2, alpha = .5) +
#   #scale_color_viridis("IMECAS", discrite = TRUE, limits = c(0,200), option = "magma") +
#   scale_color_manual(breaks = c("BUENA", "REGULAR", "MALA", "MUY MALA",
#                                 "EXTREMADAMENTE MALA"),
#                      values = viridis(5, option = "magma")) +
#   ggtitle("Air quality in MXC")
# ggsave("map.png", plot = p, width = 9, height = 8, dpi = 100)

# 
# o3 <- get_station_data_month(pollutant = "O3", 
#                              year = 2016,
#                              month = "04") 
# o3$imecas <-  convert_to_imeca(o3$value, "O3")
# no2 <- get_station_data_month(pollutant = "NO2",
#                              year = 2016,
#                              month = "04") 
# no2$imecas <-  convert_to_imeca(no2$value, "NO2")
# pm10 <- get_station_data_month(pollutant = "PM10",
#                               year = 2016,
#                               month = "04") 
# pm10 <- pm10 %>%
#   group_by(station_code) %>%
#   do(mutate(., imecas = runmean( convert_to_imeca(value, "PM10"), 24, align = "right"))) %>%
#   as.data.frame()
# 
# df <- rbind(rbind(o3,no2), pm10)
# 
# # The time is given in hours with no DST
# # GMT has no DST
# o3$datetime <- strptime(str_c(o3$date, " ", o3$hour),
#          "%Y-%m-%d %H", tz = "GMT+6") %>% as.POSIXct()
# # Convert to MXC time
# o3$datetime_mxc <- as.POSIXct(format(o3$datetime, tz="America/Mexico_City", usetz=TRUE))
# 
# # The time is given in hours with no DST
# # GMT has no DST
# df$datetime <- strptime(str_c(df$date, " ", df$hour),
#                         "%Y-%m-%d %H", tz = "GMT+6") %>% as.POSIXct()
# # Convert to MXC time
# df$datetime_mxc <- as.POSIXct(format(df$datetime, tz="America/Mexico_City", usetz=TRUE))
# 
# #mean(tail(filter(pm10,station_code == "ACO"),24)$value, na.rm = TRUE)
# 
# # Check that converting units to IMECA works
# last_df <- subset(df, datetime_mxc == mxc$time[[1]])
# if(nrow(last_df) > 0) {
#   names(last_df)[6] <- "value_unit"
#   last_df <- filter(left_join(mxc, last_df, by = c("station_code", "pollutant")), 
#                     pollutant %in% c("O3", "NO2", "PM10"))
#   print("test convert_to_imeca:")
#   #last_df$imecas_check <- convert_to_imeca(last_df$ppb, last_df$pollutant)
#   print(last_df[which(last_df$imecas != last_df$value),c("station_code", "pollutant", 
#                                                   "value", "imecas", "value_unit")])
#   #print(all(convert_to_imeca(last_df$ppb, last_df$pollutant) == last_df$value))
# }
# 
# ll_forecast <- function(o3, station_code2) {
#   days <- 30
#   return(data.frame(value = filter(o3, station_code == station_code2)$value %>% 
#                       tail(days*24) %>% convert_to_imeca("O3"),
#                     datetime = filter(o3, station_code == station_code2)$datetime_mxc %>% 
#                       tail(days*24)) %>% tail(7*24))
#   
#   
#   pol <- filter(o3, station_code == station_code2)$value %>% tail(days*24)
#   temp <- filter(o3, station_code == station_code2)$temp %>% tail(days*24)
#   wsp <- filter(o3, station_code == station_code2)$wsp %>% tail(days*24)
#   time_index <- filter(o3, station_code == station_code2)$datetime %>% tail(days*24)
#   #browser()
#   pol <- ts(pol, frequency = 24)
#   
#   if(all(is.na(pol)))
#     return(NULL)
#   if(all(is.na(tail(pol, 7*24))))
#     return(NULL)
#   
#   
#   tryCatch({
#     #pol <- tsSmooth(StructTS(pol))[,1]
#     pol <- na.interp(pol)
#     pol <- ifelse(pol < 0, 0, pol)
#     
#     xreg <- model.matrix(~is.weekend(time_index))
#     #fit <- Arima(log(pol),
#     #             order = c(2,0,0),
#     #             seasonal = list(order = c(1L, 0L, 0L), period = 24),
#     #             xreg = xreg[,-1])
#     #fit <- auto.arima(log(pol))#, xreg = xreg[,-1])
#     #newxreg <- model.matrix(~is.weekend(seq(from = max(time_index),
#     #                                        by = "hour",
#     #                                        length.out = 24)))
#     #m <- forecast(fit, h = nrow(newxreg), xreg = newxreg[,-1])
#     #plot(m)
#   },
#   error = function(e) {warning(e);return(NULL)})
#   dfit <- data.frame(value = filter(o3, station_code == station_code2)$value %>% 
#                        tail(days*24) %>% convert_to_imeca("O3"),
#                      datetime = filter(o3, station_code == station_code2)$datetime_mxc %>% 
#                        tail(days*24),
#                      type = "original",
#                      lo80 = NA,
#                      hi80 = NA,
#                      lo95 = NA,
#                      hi95 = NA)
#   if(exists("m")) {
#     dfor <- as.data.frame(m)
#     names(dfor)<-c('value','lo80','hi80','lo95','hi95')
#     dfor$value <- convert_to_imeca(exp(dfor$value), "O3")
#     dfor$hi95 <- exp(dfor$hi95)
#     dfor$lo95 <- exp(dfor$lo95)
#     dfor$hi80 <- exp(dfor$hi80)
#     dfor$lo80 <- exp(dfor$lo80)
#     #dfor <- sapply(dfor, function(x) exp(x) )  
#     dfor$datetime <- seq(from = max(dfit$datetime),
#                          by = "hour",
#                          length.out = 24)
#     dfor$type <- "forecast"
#   } else {
#     dfor <- data.frame(value = rep(NA, 24),
#                        hi95 = rep(NA, 24),
#                        lo95 = rep(NA, 24),
#                        hi80 = rep(NA, 24),
#                        lo80 = rep(NA, 24),
#                        datetime = seq(from = max(dfit$datetime),
#                                       by = "hour",
#                                       length.out = 24))
#   }
#   list(dfit %>% tail(7*24),
#        dfor)
#   
# }
# 
# #setdiff(unique(o3$station_code), unique(mxc$station_code))
# 
# o3 <- o3 %>%
#   group_by(station_code) %>%
#   mutate(max = ifelse(all(is.na(tail(value, 6))),
#                       NA_real_,
#                       max(tail(value,6), na.rm = TRUE))) %>%
#   ungroup() %>%
#   arrange(-max, station_code, date, hour) %>%
#   select(-max)
# 
# ll <- list()
# i <- 1
# for(station_code in unique(o3$station_code)) {
#   #print(station_code)
#   ll[[i]] <- ll_forecast(o3, station_code)
#   i <- i + 1
# }
# # 
# # ajm <- ll_forecast(o3, "AJM")[[1]]
# # ajm1  <- ajm[(nrow(ajm)-35):(nrow(ajm)-20),]
# # ajm2 <- tail(ajm, 12)
# # ajm1$type = "ayer"
# # ajm1$num <- 5:20
# # ajm2$type = "hoy"
# # ajm2$num <- 5:16
# # ggplot(rbind(ajm1,ajm2), aes(num, value, group = type, color = type)) +
# #   geom_line() +
# #   #geom_point() +
# #   ggtitle("Estación Ajusco Medio") +
# #   ylab("ppb") +
# #   xlab("hora") +
# #   geom_hline(yintercept = 155)
# 
# sink("../web/data/station_codes.json")
# toJSON(unique(o3$station_code), na = "null")
# sink(file = NULL)
# 
# sink("../web/data/station_names.json")
# toJSON(stations[ ,c("station_code", "station_name")])
# sink(file = NULL)
# 
# sink("../web/data/stations_o3.json")
# toJSON(ll, na = "null")
# sink(file = NULL)
# 
# 
# sink("timestamp.json")
# toJSON(mxc$time[[1]])
# sink(file = NULL)
# #ggplot(df, aes(datetime, value)) +
# #  geom_line(aes(color = type)) +
# #  scale_x_datetime(limits = c(dfit$datetime[nrow(dfit)- 750], max(dfor$datetime)))
# 
# 
