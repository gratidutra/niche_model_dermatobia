library(raster)
layers <- c("126_60", "585_60", "Current")
area_list <- data.frame()

path <- "data/workflow_maxent/km_300/"

for (layer in seq_along(layers)) {
  
  if (layers[[layer]] == "Current") {
    layer_ <-
      raster(paste0(path,
        "Final_models/M_0.2_F_lqp_Set_1_EC/Dermatobia_hominis_",
        layers_future[[layer]],"_median.asc"
      ))
    s <- summary(layer_)
    layer_[layer_ <= s["Median", ]] <- NA
  } else {
    layer_ <-
      raster(paste0(path,
        "Projection_Changes/Changes_EC/Period_/Scenario_", 
        layers_future[[layer]],
       "/continuous_comparison.tif"
      ))
    #print(summary(layer_))
    layer_[layer_ < 0] <- NA
  }
  
  cell_size <- area(layer_, na.rm = TRUE, weights = FALSE)
  # delete NAs from vector of all raster cells
  ## NAs lie outside of the rastered region, can thus be omitted

  cell_size <- area(layer_, na.rm = TRUE, weights = FALSE)
  cell_size <- cell_size[!is.na(cell_size)]
  # compute area [km2] of all cells in geo_raster
  lowland_area <- length(cell_size) * median(cell_size)
  # print area of Georgia according to raster object
  area <- round(lowland_area, digits = 1)
  new_line <- data.frame(scenario = layers[[layer]], 
                           area = area)
  area_list <- rbind(area_list, new_line)
  print(paste(layers[[layer]], area, "km2"))
}
  

actual_area  <- area_list %>% 
  filter(scenario == "Current") %>% 
  dplyr::select(area)

area_list <- area_list %>% 
  mutate('change(%)'=(area*100/actual_area[[1]])-100)
