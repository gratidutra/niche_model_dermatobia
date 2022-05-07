library(ellipsenm)
library(leaflet)
library(rgdal)
library(tidyverse)
library(magrittr)
library(raster)
library(rgbif)
library(sf)
library(spocc)
library(fasterize)
library(geobr)
library(kuenm)

# Data collection Lepav ---------------------------------------------------

lepav_dh <- 
  read.csv('~/data/raw/dermatobia_hominis_papers.csv')

# removindo  inconsistents rows 

lepav_dh[
  lepav_dh$longitude != 0 & 
    lepav_dh$latitude != 0, 
  ]

# excluding duplicates

lepav_dh <- 
  lepav_dh[
    !duplicated(paste(lepav_dh$longitude, lepav_dh$latitude)), 
    ]

# Gbif data collection ----------------------------------------------------

dh <-
  occ("Dermatobia hominis")

occs <-
  dh$gbif$data$Aedes_aegypti

occs <-
  dh$gbif$data$Dermatobia_hominis

sp_search <-
  occ_search(
    taxonKey = dh$gbif$data$Dermatobia_hominis$taxonKey[1]
  )

# Saving refs citations gbif
dir.create('output')

cit <- 
  gbif_citation(sp_search)

sink("output/gbif_ref.txt")

sapply(cit, print)

sink()

occ <- 
  occs[, c("scientificName", "longitude", "latitude")]

occ <- 
  na.omit(occ)

# defining best time interval for variables

unique(occ$scientificName)

occ <- 
  occ[occ$scientificName == "Dermatobia hominis (Linnaeus, 1781)", ]

occ$scientificName <- 
  "Dermatobia hominis"

occ <-
  occ[
    occ$longitude != 0 & occ$latitude != 0,
  ]

# excluding duplicates

occ <- 
  occ[
    !duplicated(paste(occ$longitude, occ$latitude)), 
    ]


# join datas --------------------------------------------------------------

occ %<>% 
  bind_rows(lepav_dh)

# thinning ----------------------------------------------------------------

occt <- 
  thin_data(occ, "longitude", "latitude",
  thin_distance = 25, save = T,
  name = "data/processed/D_hominis_25km"
)

# Visualização dos pontos  ------------------------------------------------

leaflet(occt) %>%
  addTiles() %>%
  addMarkers(
    lng = ~longitude, lat = ~latitude, 
    popup = paste(occ$longitude, occ$latitude)
  ) 

# Splitando o dataframe em teste treino e total ---------------------------

occt <-
  read.csv("data/processed/processed_data.csv") %>%
  dplyr::select(-X)

dir.create("data/workflow_maxent/Model_calibration")
dir.create("data/workflow_maxent/Model_calibration/Records_with_thin")

# split data

set.seed(123)

split <- kuenm_occsplit(
  occ = occt, 
  train.proportion = 0.7,
  method = "random", save = T,
  name = "Model_calibration/Records_with_thin/dhominis"
)

#-------------------Downloading, unzipping variables----------------------------

r <- getData("worldclim", var = "bio", res = 10)

#----------------------------Preparing variables--------------------------------

neotropic <-
  readOGR(
    dsn = paste0("data/shapefile"),
    layer = "neotropic",
    verbose = FALSE
  )

# Cortando as camadas de acordo com o shapefile

nwd <- gUnaryUnion(neotropic, neotropic@data$id)

cells_nona <- cellFromPolygon(r[[1]], nwd)
cellsids <- 1:ncell(r[[1]])
cell_na <- cellsids[-cells_nona[[1]]]
r[cell_na] <- NA
plot(r[[1]])

# Saving variables to new directory
dir.create("bioclim_new")

lapply(names(r), function(x) {
  writeRaster(r[[x]],
    paste0("bioclim_new/", x, ".asc"),
    overwrite = T
  )
})

# Data Exploration -----------------------------------------------------------------

# Create directory output

dir.create("output")

## only temperature variables

explore_espace(
  data = occt, species = "scientificName", longitude = "longitude",
  latitude = "latitude", raster_layers = r[[1:9]], save = T,
  name = "output/Temperature_variables.pdf"
)

## only precipitation variables

explore_espace(
  data = occt, species = "scientificName", longitude = "longitude",
  latitude = "latitude", raster_layers = r[[10:19]], save = T,
  name = "output/Precipitation_variables.pdf"
)

# low corr

lcor <- c(1, 2, 3, 10, 12, 15, 16, 18)

# exploring variable correlation in one plot for all

jpeg("output/corrplot_bioclim.jpg",
  width = 120,
  height = 120, units = "mm", res = 600
)
par(cex = 0.8)
vcor <- variable_correlation(r,
  save = T, name = "output/correlation_bioclim",
  corrplot = T, magnify_to = 3
)

dev.off()

# variables selected were bio: 1, 2, 3, 4, 10, 13, 15, 16, 17, 18, 19

dir.create("Model_calibration/Raw_variables_bio_lcor")
dir.create("Model_calibration/M_variables")

file.copy(
  from = paste0("bioclim_new/bio", lcor, ".asc"),
  to = paste0("Model_calibration/Raw_variables_bio_lcor/bio", lcor, ".asc")
)

vs <-
  kuenm_varcomb(
    var.dir = "Model_calibration/Raw_variables_bio_lcor",
    out.dir = "Model_calibration/M_variables",
    min.number = 7, in.format = "ascii", out.format = "ascii"
  )

#------------------Principal component analysis and projections-----------------

# PCA and projections

dir.create("pcas")
dir.create("pcas/pca_referenceLayers")
dir.create("pcas/pca_proj")

s1 <- 
  spca(
    layers_stack = r, layers_to_proj = r,
    sv_dir = "pcas/pca_referenceLayers", layers_format = ".asc",
    sv_proj_dir = "pcas/pca_proj"
  )

# Read the pca object (output from ntbox function)

f1 <- 
  readRDS("pcas/pca_referenceLayers/pca_object22_05_04_17_36.rds")

# Summary

f2 <- summary(f1)

# The scree plot

png(
  filename = "output/screeplot_dermatobia_hominis.png",
  width = 1200 * 1.3, height = 1200 * 1.3, res = 300
)
plot(f2$importance[3, 1:5] * 100,
  xlab = "Principal component",
  ylab = "Percentage of variance explained", ylim = c(0, 100),
  type = "b", frame.plot = T, cex = 1.5
)
points(f2$importance[2, 1:5] * 100, pch = 17, cex = 1.5)
lines(f2$importance[2, 1:5] * 100, lty = 2, lwd = 1.5)
legend(
  x = 3.5, y = 60, legend = c("Cumulative", "Non-cumulative"),
  lty = c(1, 2), pch = c(21, 17), bty = "n", cex = 0.85, pt.bg = "white"
)

dev.off()

# PCs used were pc: 1, 2, 3, 4, 5, 6
dir.create("Model_calibration/PCs_M")

nums <- 1:6

file.copy(
  from = paste0("pcas/pca_referenceLayers/PC0", nums, ".asc"),
  to = paste0("Model_calibration/PCs_M/PC0", nums, ".asc")
)

#  Criando a camada agro --------------------------------------------------

# Data agro

agro <-
  readOGR(
    dsn = paste0("mun_agro"),
    layer = "mun_agro",
    verbose = FALSE
  )

plot(agro)

agro <- agro@data

agro <-
  agro %>%
  separate(MUNICIPIO, c("MUNICIPIO", "UF"), sep = " - ") 

agro$MUNICIPIO <-
  tolower(agro$MUNICIPIO)

agro$UF <-
  toupper(agro$UF)

# Dados vetoriais

mun <-
  geobr::read_municipality(
    code_muni = "all", year = 2010, showProgress = FALSE
  )

# map

tm_shape(mun) +
  tm_polygons()

mun$name_muni <-
  tolower(mun$name_muni)

# Join

mun_da <-
  dplyr::left_join(
    x = mun, y = agro,
    by = c("name_muni" = "MUNICIPIO", "abbrev_state" = "UF")
  )

# Tem umas cidades que estão com null mas por erro de duplicata 
#values_null <- mun_da %>%
#  filter(is.na(V1))

# Raster

bio_br <- r$bio1 %>%
  raster::crop(mun_da) %>%
  raster::mask(mun_da)

# Visualizando o mapa

tm_shape(bio_br) +
  tm_raster(pal = "Spectral", title = "BIO01") +
  tm_layout(legend.position = c("left", "bottom"))


# criando o raster

mun_agro_raster <-
  fasterize::fasterize(sf = mun_da, raster = bio_br, field = "V1")

# Visualização mais bonita

map_agro <- 
  tm_shape(mun_agro_raster) +
  tm_raster(pal = "RdYlGn", title = "Estabelecimento Agropecuário") +
  tm_layout(legend.position = c("left", "bottom"))

raster::writeRaster(x = mun_agro_raster, 
                    filename = paste("Model_calibration/PCs_M/agro"),
                    suffix = agro,
                    bylayer = TRUE, 
                    options = c("COMPRESS=DEFLATE", "TFW=TRUE"), 
                    format = "ascii", 
                    progress = "text",
                    overwrite = TRUE)

dir.create("G_Variables")
dir.create("G_Variables/Set_1")
dir.create("G_Variables/Current")

file.copy(
  from = "Model_calibration/PCs_M",
  to = "G_Variables/Set_1/current"
  )
