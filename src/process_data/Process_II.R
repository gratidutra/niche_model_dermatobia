source("src/utils/functions.R")
source("src/utils/libraries.R")

list_file_current <-
  list.files(
    path = paste0(getwd(), "/data/layers/Current"),
    pattern = "\\.asc$", full.names = T
  )

current_neotropic_layer <-
  stack(list_file_current)

sp_name <- 'dhominis'

buffer_area_list <- c(100,200,250,300,400)

neotropic <-
  readOGR(
    dsn = ("data/shapefile/neotropic"),
    layer = "neotropic",
    verbose = FALSE
  )

for (km in seq_along(buffer_area_list)) {
    # Buffer Area -------------------------------------------------------------
    path_workflow <- paste0("data/workflow_maxent")
    km <- buffer_area_list[[km]]
    path_calibration <- paste0(path_workflow, "/km_", km)
    dir_create(path_calibration)
    
    occ <- read.csv(paste0(
      path_workflow, "/", sp_name, "_joint.csv"
    )) %>% select(-X)
    
    
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
    #buffer_area <- sp::disaggregate(buffer_area)
    
    ## reproject
    buffer_area <- spTransform(buffer_area, WGS84)
    
    ## make spatialpolygondataframe
    df <- data.frame(species = rep(sp_name, length(buffer_area)))
    buffer_area <- SpatialPolygonsDataFrame(buffer_area, data = df, match.ID = FALSE)
    
    ## write area as shapefile
    dir_create(paste0(path_calibration, "/Calibration_area_", km))
    dir_create(paste0(path_calibration, "/Calibration_area_", km, "/shapefile"))
    writeOGR(buffer_area,
             paste0(path_calibration, "/Calibration_area_", km, "/shapefile"),
             "M",
             driver = "ESRI Shapefile"
    )
    
    tm_shape(neotropic) +
      tm_polygons(border.alpha = 0.3) +
      tm_shape(occ_sp) +
      tm_dots(size = 0.05) +
      tm_shape(buffer_area) +
      tm_borders()
    
    M <- buffer_area
    
    # masking layers to M
    mask_layers <- mask(crop(current_neotropic_layer, M), M)
    
    # saving masked layers as ascii files
    lapply(names(mask_layers), function(x) {
      writeRaster(mask_layers[[x]],
                  paste0(
                    path_calibration,
                    "/Calibration_area_", km, "/", x, ".asc"
                  ),
                  overwrite = T
      )
    })
  }