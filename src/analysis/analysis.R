library(ellipsenm)
library(kuenm)
library(rgdal)
library(tidyverse)
library(rgeos)
library(magrittr)
library(raster)
library(sf)
library(maps)
library(ntbox)

#-----------------------Model candidate models----------------------------------
occ_joint <- "data/workflow_maxent/Model_calibration/Records_with_thin/dhominis_joint.csv"
occ_tra <- "data/workflow_maxent/Model_calibration/Records_with_thin/dhominis_train.csv"
M_var_dir <- "data/workflow_maxent/Model_calibration/PCs_M"
batch_cal <- "data/workflow_maxent/Candidate_models"
out_dir <- "data/workflow_maxent/Candidate_Models"
reg_mult <- c(0.1, 0.25)
f_clas <- c("lq", "lqp", "q")
args <- NULL
maxent_path <- getwd()
wait <- FALSE
run <- TRUE

kuenm_cal(
  occ.joint = occ_joint, occ.tra = occ_tra, M.var.dir = M_var_dir,
  batch = batch_cal, out.dir = out_dir, reg.mult = reg_mult,
  f.clas = f_clas, args = args, maxent.path = maxent_path,
  wait = wait, run = run
)

#-----------------------Model evaluating models---------------------------------

occ_test <- "Model_calibration/Records_with_thin/dhominis_test.csv"
out_eval <- "Calibration_results"
threshold <- 5
rand_percent <- 50
iterations <- 500
kept <- TRUE
selection <- "OR_AICc"
# Note, some of the variables used here as arguments were already created 
# for the previous function

cal_eval <- kuenm_ceval(
  path = out_dir, occ.joint = occ_joint, occ.tra = occ_tra,
  occ.test = occ_test, batch = batch_cal, out.eval = out_eval,
  threshold = threshold, rand.percent = rand_percent,
  iterations = iterations, kept = kept, selection = selection
)

#----------------------------------Final Models ---------------------
dir.create("Final_models")

batch_fin <- "Final_models"
mod_dir <- "Final_Models"
rep_n <- 5
rep_type <- "Bootstrap"
jackknife <- TRUE
out_format <- "cloglog"
project <- TRUE
G_var_dir <- "G_variables"
ext_type <- "all"
write_mess <- FALSE
write_clamp <- FALSE
wait1 <- FALSE
run1 <- TRUE
args <- NULL


kuenm_mod(
  occ.joint = occ_joint, M.var.dir = M_var_dir, out.eval = out_eval,
  batch = batch_fin, rep.n = rep_n, rep.type = rep_type,
  jackknife = jackknife, out.dir = mod_dir, out.format = out_format,
  project = project, G.var.dir = G_var_dir, ext.type = ext_type,
  write.mess = write_mess, write.clamp = write_clamp,
  maxent.path = maxent_path, args = args, wait = wait1, run = run1
)

replicates <- TRUE
out_feval <- "Final_Models_evaluation"

fin_eval <-
  kuenm_feval(
    path = mod_dir, occ.joint = occ_joint, occ.ind = occ_test, 
    replicates = replicates, out.eval = out_feval, threshold = threshold, 
    rand.percent = rand_percent, iterations = iterations, 
    parallel.proc = paral_proc
  )
