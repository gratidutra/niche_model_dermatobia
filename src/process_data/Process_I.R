source("src/utils/libraries.R")
source("src/utils/functions.R")

load_dot_env(file = ".env")
sp_name <- "dhominis"

df <-
  read.csv("data/raw/dermatobia_hominis_papers.csv") %>%
  rename(
    species = scientificName
  ) %>%
  mutate(species = gsub("_", " ", species))

splist <-
  levels(as.factor(df$species))

name <- name_suggest("Dermatobia hominis")

name$data$key

# problema no limite de requisições

occ <- occ_download(
  pred_in("taxonKey", name$data$key),
  pred("hasCoordinate", TRUE),
  format = "SIMPLE_CSV",
  user = Sys.getenv('USER_GBIF'), pwd = Sys.getenv('PWD_GBIF'),
  email = Sys.getenv('EMAIL')
)

all_species <- 
  occ_download_get(key = '0025739-231002084531237', overwrite = TRUE) %>% 
  occ_download_import

all_species_gbif <-
  all_species %>%
  dplyr::select(species, decimalLatitude, decimalLongitude) %>%
  rename(longitude = decimalLongitude,
         latitude = decimalLatitude) %>% 
  drop_na()

# Species Link ------------------------------------------------------------

data_splink_raw <-
  rspeciesLink(
    filename = "data_splink",
    species = 'Dermatobia hominis',
    Coordinates = "Yes",
    CoordinatesQuality = "Good"
  )

data_splink <- 
  data_splink_raw %>%
  rename(species = scientificName,
         longitude = decimalLongitude,
         latitude = decimalLatitude) %>%
  dplyr::select(species, latitude, longitude) %>%
  mutate(
    latitude = as.numeric(latitude),
    longitude = as.numeric(longitude)
  )

# Unindo e tratando o df final--------------------------------------------------

data_bind <-
  all_species_gbif %>%
  bind_rows(data_splink, df)

# removendo as duplicatas

data_processed_1 <-
  data_bind[
    !duplicated(paste(
      data_bind$species,
      data_bind$longitude,
      data_bind$latitude
    )),
  ]

dir_create("data/processed")

# shapefile

neotropic <-
  readOGR(
    dsn = ("data/shapefile/neotropic"),
    layer = "neotropic",
    verbose = FALSE
  )

# identificando pontos fora do shape

data_processed_1["inout"] <- over(
  SpatialPoints(data_processed_1[
    , c("longitude", "latitude")
  ], proj4string = CRS(projection(neotropic))),
  as(neotropic, "SpatialPolygons")
)

data_processed_2 <-
  data_processed_1 %>%
  drop_na(.) %>% 
  dplyr::select(species, longitude, latitude)
  
# salvando csv

write.csv(
  data_processed_2,
  paste0("data/processed/",sp_name,"_processed.csv")
  )

# criando objeto pro plot via tmap e plotando

data_point_plot <-
  data_processed_2 %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>%
  st_cast("POINT")

tm_shape(neotropic) +
  tm_polygons(border.alpha = 0.3) +
  tm_shape(data_point_plot) +
  tm_dots(size = 0.05)

# thin & split ---------------------------------------------------------
path_workflow <- "data/workflow_maxent" 
dir_create(path_workflow)
occt <- 
  thin_data(data_processed_2, "longitude", "latitude",
            thin_distance = 20, save = T,
            name = "data/processed/D_hominis_25km"
  )

occt_point_plot <-
  occt %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>%
  st_cast("POINT")

tm_shape(neotropic) +
  tm_polygons(border.alpha = 0.3) +
  tm_shape(occt_point_plot) +
  tm_dots(size = 0.05)

set.seed(123)

kuenm_occsplit(
  occ = occt, 
  train.proportion = 0.7,
  method = "random", save = T,
  name = paste0(path_workflow, "/", sp_name)
)
