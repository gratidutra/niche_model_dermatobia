source("src/utils/libraries.R")
source("src/utils/functions.R")

data <- read_excel("data/selected_variables.xlsx") %>%
  dplyr::mutate(across(2:6, char_to_list, .names = "{.col}")) 

sp_name <- data$species

buffer_area_list <- colnames(data)[2:6]

for (km in seq_along(buffer_area_list)) {
    path_workflow <- paste0("data/workflow_maxent/")
    path_calibration <- paste0(path_workflow, "/km_", buffer_area_list[[km]])
    
    loc_variables <- data %>%
      dplyr::filter(species == sp_name) %>%
      dplyr::select(buffer_area_list[[km]])
    
    flat_list <- as.numeric(unlist(loc_variables[[1]]))
    print(flat_list)
    
    dir_create(
      paste0(
        path_calibration,
        "/G_variables"
      )
    )
    
    dir_create(
      paste0(
        path_calibration, "/G_variables/Set_1"
      )
    )
    
    dir_create(
      paste0(
        path_calibration, "/G_variables/Set_2"
      )
    )
    
    layers_list <-
      c(
        "Current",
        "future_layer_can_126_60", "future_layer_can_585_60",
        "future_layer_mc_126_60", "future_layer_mc_585_60"
      )
    for (layer in seq_along(layers_list)) {
      dir_create(
        paste0(
          path_calibration, "/G_variables/Set_1/", layers_list[[layer]]
        )
      )
      
      file.copy(
        from = paste0("data/layers/", layers_list[[layer]], "/bio", flat_list, ".asc"),
        to = paste0(path_calibration, "/G_variables/Set_1/", layers_list[[layer]], "/bio", flat_list, ".asc")
      )
      
      dir_create(
        paste0(
          path_calibration, "/G_variables/Set_2/", layers_list[[layer]]
        )
      )
      
      pcs <- 1:5
      
      file.copy(
        from = paste0(path_calibration, "/pca_", buffer_area_list[[km]] , "/pca_proj_" , layers_list[[layer]], "/PC0", pcs, ".asc"),
        to = paste0(path_calibration, "/G_variables/Set_2/", layers_list[[layer]], "/PC0", pcs, ".asc")
      )
    }
}
