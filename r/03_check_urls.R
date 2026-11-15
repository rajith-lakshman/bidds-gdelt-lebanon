# Check which article URLs for the key weeks are still live
# (paper: URL_check_2015.R / URL_check_2015_v2.R, Annexe A step 5).
#
# Input : data/sample/fct_case_event_urls.csv (one row per url x ISO week)
# Output: data/url_check.csv (git-ignored); re-running only checks new URLs.
#
# Requires: tidyverse, httr2, here

source(here::here("r", "config.R"))

library(tidyverse)
library(httr2)
library(readr)

urls <- read_csv(file.path(cfg$sample_dir, "fct_case_event_urls.csv"), show_col_types = FALSE) |>
  filter(iso_week %in% cfg$key_weeks)

cache_path <- here("data", "url_check.csv")
done <- if (file.exists(cache_path)) read_csv(cache_path, show_col_types = FALSE) else NULL
todo <- urls |> distinct(url) |> filter(!url %in% done$url)
message(nrow(todo), " URLs to check (", nrow(urls) - nrow(todo), " rows already cached or duplicated)")

check_one <- function(resp) {
  if (!inherits(resp, "httr2_response")) {
    return(tibble(status = NA_integer_, final_url = NA_character_, error = conditionMessage(resp)))
  }
  tibble(status = resp_status(resp), final_url = resp_url(resp), error = NA_character_)
}

if (nrow(todo) > 0) {
  reqs <- lapply(todo$url, function(u) {
    request(u) |>
      req_user_agent("bidds-gdelt-lebanon url check (research)") |>
      req_timeout(10) |>
      req_error(is_error = \(resp) FALSE)  # keep 4xx/5xx as responses
  })

  resps <- req_perform_parallel(reqs, on_error = "continue", max_active = 10, progress = TRUE)

  new <- bind_cols(todo, map_dfr(resps, check_one))
  done <- bind_rows(done, new)
  write_csv(done, cache_path)
}

# A URL counts as live if it returns 200 and did not redirect to a bare homepage,
# which is how most expired news links resolve.
is_homepage <- function(x) str_detect(x, "^https?://[^/]+/?$")

result <- urls |>
  left_join(done, by = "url") |>
  mutate(
    homepage = is_homepage(final_url),
    live = !is.na(status) & status == 200 & !homepage,
    # Annexe A step 6: keyword hit in the URL itself, usable even when the page is gone
    keyword_in_url = str_detect(
      str_to_lower(url), "garbage|stink|waste|trash|rubbish|sukleen|naameh"
    )
  )

result |>
  group_by(iso_week) |>
  summarise(
    urls = n(),
    live_share = mean(live),
    live = sum(live),
    keyword_in_url = sum(keyword_in_url),
    .groups = "drop"
  )
