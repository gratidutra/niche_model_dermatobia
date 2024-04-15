library(kuenm)
# Params ------------------------------------------------------------------
specie_name <- "Dermatobia_hominis"
fmod_dir <-
  paste0("data/workflow_maxent/km_300/Final_models")

format <- "asc"
project <- TRUE
stats <- c("med", "range")
rep <- TRUE
scenarios <-
  c(
    "Current", "future_layer_can_126_60",
    "future_layer_can_585_60",
    "future_layer_mc_126_60",
    "future_layer_mc_585_60"
  )

ext_type <- c("E", "EC", "NE")
out_dir <-
  paste0("data/workflow_maxent/km_300/Final_Model_Stats")

kuenm_modstats(
  sp.name = specie_name, fmod.dir = fmod_dir,
  format = format, project = project,
  statistics = stats, replicated = rep,
  proj.scenarios = scenarios,
  ext.type = ext_type, out.dir = out_dir
)

# project changes ---------------------------------------------------------

occ_joint <-
  paste0("data/workflow_maxent/dhominis_joint.csv")
thres <- 5
curr <- "Current"
emi_scenarios <- c("126_60", "585_60")
c_mods <- c("future_layer_can", "future_layer_mc")
ext_type <- c("E", "EC", "NE")
out_dir1 <- paste0("data/workflow_maxent/km_300/Projection_Changes")

kuenm_projchanges(
  occ = occ_joint, fmod.stats = out_dir, threshold = thres, current = curr,
  emi.scenarios = emi_scenarios, clim.models = c_mods, ext.type = ext_type,
  out.dir = out_dir1
)