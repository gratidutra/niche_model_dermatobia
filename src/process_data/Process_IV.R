source("src/utils/functions.R")
source("src/utils/libraries.R")

data <- read_excel('data/selected_variables.xlsx') %>% 
  mutate(across(2:6, char_to_list, .names = "{.col}")) 

species_list <- data$species

buffer_area_list <- colnames(data)[2:6]

neotropic <-
  readOGR(
    dsn = ("data/shapefile/neotropic"),
    layer = "Neotropic",
    verbose = FALSE
  )

for (km in seq_along(buffer_area_list)) {
    # Buffer Area -------------------------------------------------------------
    path_workflow <- paste0("data/workflow_maxent/")
    km <- buffer_area_list[[km]]
    path_calibration <- paste0(path_workflow, "/km_", km)
    
    # low corr
    
    loc_variables <- data %>% 
      dplyr::filter(species == sp_name) %>% 
      dplyr::select(km) 
    
    flat_list <- as.numeric(unlist(loc_variables[[1]]))
    
    # Workflow Kuenm -> Model Calibration -------------------------------------
    
    dir_create(
      paste0(
        path_calibration,
        "/Model_calibration"
      )
    )
    
    dir_create(
      paste0(
        path_calibration, "/Model_calibration/M_variables"
      )
    )
    
    dir_create(
      paste0(
        path_calibration, "/Model_calibration/M_variables/Set_1"
      )
    )
    
    file.copy(
      from = paste0(path_calibration, "/Calibration_area_", km, "/bio", flat_list, ".asc"),
      to = paste0(path_calibration, "/Model_calibration/M_variables/Set_1/bio", flat_list, ".asc")
    )
    
    #------------------Principal component analysis and projections-----------------
    
    layers_list <-
      c(
        "Current",
        "future_layer_can_126_60", "future_layer_can_585_60",
        "future_layer_mc_126_60", "future_layer_mc_585_60"
      )
    
    # PCA and projections
    dir_create(paste0(path_calibration,"/pca_", km))
    dir_create(paste0(path_calibration,"/pca_", km, "/pca_referenceLayers"))
    dir_create(paste0(path_calibration,"/pca_", km, "/pca_proj"))
    
    # dir_create(paste0("G_Variables/Set_2"))
    
    for (layer in seq_along(layers_list)) {
      do_pca(
        set = 2,
        time = layers_list[[layer]],
        path_layer_stack = paste0(path_calibration, "/Calibration_area_", km),
        #path_layer_proj = NULL,
        path_layer_proj = paste0("data/layers/", layers_list[[layer]]),
        sv_dir = paste0(path_calibration,"/pca_", km, "/", layers_list[[layer]]),
        #sv_proj_dir = NULL,
        sv_proj_dir = paste0(path_calibration,"/pca_", km, "/pca_proj_", layers_list[[layer]]),
        nums = 1:5,
        m_dir = paste0(path_calibration,"/Model_calibration/M_variables/Set_2"),
        g_dir = NULL,
        from_proj = FALSE
      )
    }
}
