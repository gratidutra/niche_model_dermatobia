source('src/utils/functions.R')
source('src/utils/libraries.R')

path_workflow <- 'data/workflow_maxent'
km <- 250
path_cal <- paste0(path_workflow,'/km_', km) 
sp_name <- 'dhominis'

occ <- read.csv(paste0(
  path_workflow, "/", sp_name, "_train.csv")
)

list_file_current <- 
  list.files(
    path = paste0(path_cal, "/Calibration_area_", km ),
    pattern = "\\.asc$", full.names = T
  )

varsm <- 
  stack(list_file_current)


# Pearson Correlation  ----------------------------------------------------

temp <- stack(varsm$bio1,varsm$bio2, varsm$bio3, varsm$bio4,
              varsm$bio5, varsm$bio6, varsm$bio7, varsm$bio8, 
              varsm$bio9, varsm$bio10, varsm$bio11)

prec <- stack(varsm$bio12,varsm$bio13, varsm$bio14, varsm$bio15,
              varsm$bio16, varsm$bio17, varsm$bio18, varsm$bio19)

## only temperature variables

explore_espace(
  data =  occ, species = "species", longitude = "longitude",
  latitude = "latitude", raster_layers = temp, save = T,
  name = paste0("output/Temperature_variables_",km,".pdf")
)

## only precipitation variables

explore_espace(
  data = occ, species = "species", longitude = "longitude",
  latitude = "latitude", raster_layers = prec, save = T,
  name = paste0("output/Precipitation_variables_",km,".pdf")
)

# low corr

lcor <- c(1, 2, 3, 12, 14, 18)

# # exploring variable correlation in one plot for all
# 
# jpeg(paste0("output/corrplot_bioclim_",km,".jpg"),
#      width = 120,
#      height = 120, units = "mm", res = 600
# )
# par(cex = 0.8)
# 
# vcor <- 
#   variable_correlation(
#     varsm,
#     save = T, name = paste0("output/correlation_bioclim_", km),
#     corrplot = T, magnify_to = 3
#   )
# 
# dev.off()

# Workflow Kuenm -> Model Calibration -------------------------------------

dir_create(
  paste0(
    path_cal, 
    "/Model_calibration")
)

dir_create(
  paste0(
    path_cal, "/Model_calibration/M_variables")
)

dir_create(
  paste0(
    path_cal,"/Model_calibration/M_variables/Set_1")
)

file.copy(
  from = paste0(path_cal,"/Calibration_area_",km ,"/bio", lcor, ".asc"),
  to = paste0(path_cal,"/Model_calibration/M_variables/Set_1/bio", lcor, ".asc")
)

# vs <-
#   kuenm_varcomb(
#     var.dir = "data/workflow_maxent/Model_calibration/Raw_variables_bio_lcor",
#     out.dir = "data/workflow_maxent/Model_calibration/M_variables",
#     min.number = 7, in.format = "ascii", out.format = "ascii"
#   )


# G_Variables -------------------------------------------------------------

dir_create(paste0(path_cal,"/G_Variables"))
dir_create(paste0(path_cal,"/G_Variables/Set_1"))

layers_list <-
  c(
    "Current", "future_layer_can_126_60", "future_layer_can_585_60",
    "future_layer_mc_126_60", "future_layer_mc_585_60"
  )

for (layer in seq_along(layers_list)) {
  dir_create(paste0(path_cal,"/G_Variables/Set_1/", layers_list[[layer]]))
  
  file.copy(
    from = paste0(
      "data/layers/", layers_list[[layer]], "/bio", lcor, ".asc"
    ),
    to = paste0(
       path_cal,"/G_Variables/Set_1/", layers_list[[layer]], "/bio", lcor, ".asc"
    )
  )
}

#------------------Principal component analysis and projections-----------------
# PCA and projections
dir_create(paste0(path_cal, "/pcas_", km))
dir_create(paste0(path_cal,"/pcas_", km, "/pca_referenceLayers"))
dir_create(paste0(path_cal,"/pcas_", km, "/pca_proj"))

dir_create(paste0(path_cal, "/G_Variables/Set_2"))

for (layer in seq_along(layers_list)) {
  do_pca(
    set = 2, time = layers_list[[layer]],
    path_layer_stack = paste0(path_cal, "/Calibration_area_", km),
    path_layer_proj = paste0("data/layers/", layers_list[[layer]]),
    sv_dir = paste0(path_cal, "/pcas_", km, "/",layers_list[[layer]]),
    sv_proj_dir = paste0(path_cal, "/pcas_", km, "/pca_proj_", layers_list[[layer]]),
    nums = 1:5,
    m_dir = paste0(path_cal, "/Model_calibration/M_variables/Set_2"),
    g_dir = paste0(path_cal, "/G_Variables"), 
    from = "sv_proj_dir"
  )
}
