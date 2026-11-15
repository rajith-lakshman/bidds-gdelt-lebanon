# Shared settings for the R scripts. Source this file first: source(here::here("r", "config.R"))

library(here)

cfg <- list(
  # BigQuery location of the dbt marts (matches the dbt profile / python/export_marts.py)
  project = Sys.getenv("GCP_PROJECT_ID"),   # set in .Renviron or the shell; only needed by 01_get_data.R
  dataset = Sys.getenv("BQ_DATASET", "bidds_gdelt_dev"),

  # Paths
  sample_dir = here("data", "sample"),
  map_dir    = here("data", "map"),      # GADM boundaries are cached here (git-ignored)
  fig_dir    = here("docs", "figures"),

  # Case-study settings (Garbage Crisis 2015, paper section 3.1)
  case_label = "WB_1797_SOLID_WASTE",
  key_weeks  = c(29, 31, 35)              # ISO weeks the paper discusses
)

dir.create(cfg$fig_dir, recursive = TRUE, showWarnings = FALSE)
