# Download the three dbt marts from BigQuery (paper: get_data_2015.R).
# Writes the same CSVs as python/export_marts.py, so either script can refresh them.
#
# Requires: bigrquery, readr, here. Authenticate once with bigrquery::bq_auth().

source(here::here("r", "config.R"))

library(bigrquery)
library(readr)

if (!nzchar(cfg$project)) {
  stop("Set GCP_PROJECT_ID to your Google Cloud project id (see .env.example).", call. = FALSE)
}

marts <- c("fct_weekly_counts", "fct_case_event_locations", "fct_case_event_urls")

dir.create(cfg$sample_dir, recursive = TRUE, showWarnings = FALSE)

for (mart in marts) {
  df <- bq_table_download(
    bq_table(cfg$project, cfg$dataset, mart),
    page_size = 500
  )
  write_csv(df, file.path(cfg$sample_dir, paste0(mart, ".csv")))
  message(mart, ": ", nrow(df), " rows")
}
