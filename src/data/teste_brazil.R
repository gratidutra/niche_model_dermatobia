bio_6 <- r$bio6 %>%
  raster::crop(mun_da) %>%
  raster::mask(mun_da)

lista_layers <- stack(bio_1, bio_2, bio_3, 
                 bio_4, bio_5, bio_6,
                 bio_7, bio_8, bio_9, 
                 bio_10, bio_11, bio_12,
                 bio_13, bio_14, bio_15, 
                 bio_16, bio_17, bio_18,
                 bio_19)

dir.create('data/workflow_maxent/pcas/pca_referenceLayers_b')

s1 <- 
  spca(
    layers_stack = lista_layers, layers_to_proj = r,
    sv_dir = "data/workflow_maxent/pcas/pca_referenceLayers_b", 
    layers_format = ".asc",
    sv_proj_dir = "data/workflow_maxent/pcas/pca_proj"
  )

dir.create("data/workflow_maxent/Model_calibration/PCs_M_b")
dir.create("data/workflow_maxent/Model_calibration/PCs_M_b/Set_1")

nums <- 1:5

file.copy(
  from = paste0("data/workflow_maxent/pcas/pca_referenceLayers_b/PC0", nums, ".asc"),
  to = paste0("data/workflow_maxent/Model_calibration/PCs_M_b/Set_1/PC0", nums, ".asc")
)
