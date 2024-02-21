source("src/functions.R")
source("src/libraries.R")

neotropic <-
  readOGR(
    dsn = ("data/shapefile/neotropic"),
    layer = "neotropic",
    verbose = FALSE
  )

path_cmip6 <- paste0("data/layers")
dir_create(path_cmip6)

current_layer <- 
  geodata::worldclim_global(
    "bio",
    res = 10,
    path = getwd()
  )

current <- 
  crop_raster_cmip6(
    current_layer, neotropic,
    paste0(path_cmip6,"/Current"))

# Future ------------------------------------------------------------------
future_layer_mc_126_60 <-
  geodata::cmip6_world(model='MIROC6', 
                       ssp='126', 
                       time = "2041-2060",
                       var = 'bioc',
                       res=10, path = getwd())

mc_126 <- 
  crop_raster_cmip6(
    future_layer_mc_126_60, neotropic, 
    paste0(path_cmip6,"/future_layer_mc_126_60"))

future_layer_mc_585_60 <-
  geodata::cmip6_world(model='MIROC6', 
                       ssp='585', 
                       time = "2041-2060",
                       var = 'bioc',
                       res=10, path = getwd()
  )

mc_585 <- crop_raster_cmip6(
  future_layer_mc_585_60, neotropic, 
  paste0(path_cmip6,"/future_layer_mc_585_60"))

future_layer_can_126_60 <-
  geodata::cmip6_world(model='CanESM5', 
                       ssp='126', 
                       time = "2041-2060",
                       var = 'bioc',
                       res=10, path = getwd())

can_126 <- 
  crop_raster_cmip6(
    future_layer_can_126_60, neotropic, 
    paste0(path_cmip6,"/future_layer_can_126_60"))

future_layer_can_585_60 <-
  geodata::cmip6_world(model='CanESM5', 
                       ssp='585', 
                       time = "2041-2060",
                       var = 'bioc',
                       res=10, path = getwd()
  )

can_585 <- 
  crop_raster_cmip6(
    future_layer_can_585_60, neotropic, 
    paste0(path_cmip6,"/future_layer_can_585_60"))
