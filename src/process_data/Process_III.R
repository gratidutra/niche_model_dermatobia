source("src/utils/functions.R")
source("src/utils/libraries.R")

sp_name <- "dhominis"

buffer_area_list <- c(100, 200, 250, 300, 400)

neotropic <-
  readOGR(
    dsn = ("data/layers/Current"),
    layer = "neotropic",
    verbose = FALSE
  )

for (km in seq_along(buffer_area_list)) {
    # Buffer Area -------------------------------------------------------------
    path_workflow <- paste0("data/workflow_maxent")
    km <- buffer_area_list[[km]]
    path_calibration <- paste0(path_workflow, "/km_", km)
    occ <- read.csv(
      paste0(
        path_workflow, "/", sp_name, "_train.csv"
      )
    )
    
    list_file_current <-
      list.files(
        path = paste0(path_calibration, "/Calibration_area_", km),
        pattern = "\\.asc$", full.names = T
      )
    
    varsm <-
      stack(list_file_current)
    
    
    # Pearson Correlation  ----------------------------------------------------
    
    temp <- stack(
      varsm$bio1, varsm$bio2, varsm$bio3, varsm$bio4,
      varsm$bio5, varsm$bio6, varsm$bio7, varsm$bio8,
      varsm$bio9, varsm$bio10, varsm$bio11
    )
    
    prec <- stack(
      varsm$bio12, varsm$bio13, varsm$bio14, varsm$bio15,
      varsm$bio16, varsm$bio17, varsm$bio18, varsm$bio19
    )
    
    dir_create(paste0(path_workflow,'/output'))
    
    ## only temperature variables
    
    explore_espace(
      data = occ, species = "species", longitude = "longitude",
      latitude = "latitude", raster_layers = temp, save = T,
      name = paste0(path_workflow, "/output/Temperature_variables_", km, ".pdf")
    )
    
    ## only precipitation variables
    
    explore_espace(
      data = occ, species = "species", longitude = "longitude",
      latitude = "latitude", raster_layers = prec, save = T,
      name = paste0(path_workflow, "/output/Precipitation_variables_", km, ".pdf")
    )
  }
