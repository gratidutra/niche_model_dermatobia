source("src/utils/functions.R")
source("src/utils/libraries.R")

path_calibration <- paste0(path_workflow, "/km_", km)

list_file_current <-
  list.files(
    path = paste0(getwd(), "/data/layers/Current"),
    pattern = "\\.asc$", full.names = T
  )

current_neotropic_layer <-
  stack(list_file_current)

sp_name <- 'dhominis'

km <- 600

neotropic <-
  readOGR(
    dsn = ("data/shapefile/neotropic"),
    layer = "neotropic",
    verbose = FALSE
  )


occ <- read.csv(paste0(
  path_workflow, "/", sp_name, "_joint.csv"
)) %>% dplyr::select(-X)


WGS84 <- CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")
occ_sp <- SpatialPointsDataFrame(
  coords = occ[, 2:3], data = occ,
  proj4string = WGS84
)

## project the points using their centroids as reference
centroid <- gCentroid(occ_sp, byid = FALSE)
AEQD <- CRS(paste("+proj=aeqd +lat_0=", centroid@coords[2], " +lon_0=", centroid@coords[1],
                  " +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs",
                  sep = ""
))

occ_pr <- spTransform(occ_sp, AEQD)

## create a buffer based on a 500 km distance
buffer_area <- gBuffer(occ_pr, width = km * 1000, quadsegs = 30)
#debugar, essa parte ta dando erro mais pra frente por não funcionar 
buffer_area <- disaggregate(buffer_area)

## reproject
buffer_area <- spTransform(buffer_area, WGS84)
