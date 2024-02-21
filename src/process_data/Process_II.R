source("src/utils/functions.R")
source("src/utils/libraries.R")

neotropic <-
  readOGR(
    dsn = ("data/shapefile/neotropic"),
    layer = "neotropic",
    verbose = FALSE
  )

# Buffer Area -------------------------------------------------------------
path_workflow <- 'data/workflow_maxent'
sp_name <- 'dhominis'
km <- 300
path_cal <- paste0(path_workflow,'/km_', km) 
dir_create(path_cal)

occ <- read.csv(paste0(
  path_workflow , "/", sp_name, "_joint.csv")
)

list_file_current <- 
  list.files(
    path = paste0(path_cmip6, "/", "Current"),
    pattern = "\\.asc$", full.names = T
  )

current_neotropic_layer <- 
  stack(list_file_current)

WGS84 <- CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")
occ_sp <- SpatialPointsDataFrame(coords = occ[, 2:3], data = occ,
                                 proj4string = WGS84)

## project the points using their centroids as reference
centroid <- gCentroid(occ_sp, byid = FALSE)
AEQD <- CRS(paste("+proj=aeqd +lat_0=", centroid@coords[2], " +lon_0=", centroid@coords[1],
                  " +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs", sep = ""))

occ_pr <- spTransform(occ_sp, AEQD)

## create a buffer based on a 500 km distance
buff_area <- gBuffer(occ_pr, width = km*1000, quadsegs = 30)
buff_area <- disaggregate(buff_area)

## reproject
buff_area <- spTransform(buff_area, WGS84)

## make spatialpolygondataframe
df <- data.frame(species = rep(sp_name, length(buff_area)))
buff_area <- SpatialPolygonsDataFrame(buff_area, data = df, match.ID = FALSE)

## write area as shapefile
dir_create(paste0(path_workflow, path_cal,"/Calibration_area_", km))
writeOGR(buff_area, 
         paste0(path_workflow, path_cal,"/Calibration_area_", km), 
         "M", driver = "ESRI Shapefile")

tm_shape(neotropic) +
  tm_polygons(border.alpha = 0.3) +
  tm_shape(occ_sp) +
  tm_dots(size = 0.05) +
  tm_shape(buff_area) +
  tm_borders()

M <- buff_area

# masking layers to M
varsm <- mask(crop(current_neotropic_layer, M), M)

# saving masked layers as ascii files
lapply(names(varsm), function(x){
  writeRaster(varsm[[x]], 
              paste0(path_workflow, path_cal,
                     "/Calibration_area_", km, "/", x,".asc"), overwrite=T)
})
