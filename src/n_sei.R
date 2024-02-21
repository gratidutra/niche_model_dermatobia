library(kuenm)
library(raster)
library(tidyverse)

help("kuenm_proc")

test <-read_csv("data/workflow_maxent/dhominis_test.csv") %>% 
  select(longitude, latitude)
model <- 
  raster::raster('data/workflow_maxent/Final_Models/M_2_F_lqp_Set_02_E/Dermatobia_hominis_avg.asc')


proc_derma <- kuenm_proc(occ.test = as.data.frame(test), 
           model=model, threshold = 5, rand.percent = 50,
           iterations = 500)


# nosso -------------------------------------------------------------------
conti_model <- raster::raster(system.file("extdata",
                                          "ambystoma_model.tif",
                                          package="ntbox"))

# Read validation (test) data
test_data <- read.csv(system.file("extdata",
                                  "ambystoma_validation.csv",
                                  package = "ntbox"))

# Filter only presences as the Partial ROC only needs occurrence data
test_data <- dplyr::filter(test_data, presence_absence==1)
test_data <- test_data[,c("longitude","latitude")]

example_pack <- kuenm_proc(test_data, 
           model=conti_model, threshold = 5, rand.percent = 50,
           iterations = 500)
summary(example_pack)
