raster_data <- 
  raster("data/workflow_maxent/km_100/Final_models/M_0.7_F_lq_Set_1_E/Dermatobia_hominis_Current_avg.asc")

raster_data[raster_data <=0.4] <- NA

cell_size<-area(raster_data, na.rm=TRUE, weights=FALSE)
#delete NAs from vector of all raster cells
##NAs lie outside of the rastered region, can thus be omitted

cell_size<-area(raster_data, na.rm=TRUE, weights=FALSE)
cell_size<-cell_size[!is.na(cell_size)]
#compute area [km2] of all cells in geo_raster
lowland_area<-length(cell_size)*median(cell_size)
#print area of Georgia according to raster object
print(paste('Area of lowland regions (0-999 m):',round(lowland_area, digits=1),'km2'))

plot(raster_data)

summary(cell_size)
