# Weekly counts, weekly tone and maps for the Garbage Crisis 2015
# (paper: map_2015.R, Figure 3.1). Reads the dbt marts exported to data/sample/.
#
# Requires: tidyverse, sf, geodata, ggrepel, here

source(here::here("r", "config.R"))

library(tidyverse)
library(sf)
library(ggrepel)
library(scales)
library(geodata)

weekly    <- read_csv(file.path(cfg$sample_dir, "fct_weekly_counts.csv"), show_col_types = FALSE)
locations <- read_csv(file.path(cfg$sample_dir, "fct_case_event_locations.csv"), show_col_types = FALSE)

# ---- 1. Weekly counts --------------------------------------------------------
# Grey areas: all merged events and events whose articles carry the PROTEST theme.
# Red line: events whose articles carry the case theme, on a secondary axis.
scale_factor <- max(weekly$merged_events) / max(weekly$case_theme_events)

label_at <- function(col, wk) weekly[[col]][weekly$iso_week == wk]
label_wk <- weekly$iso_week[which.max(weekly$merged_events)]

p_counts <- ggplot(weekly, aes(iso_week)) +
  geom_area(aes(y = merged_events), fill = "grey70") +
  geom_area(aes(y = protest_theme_events), fill = "grey88") +
  geom_line(aes(y = case_theme_events * scale_factor), colour = "darkred", linewidth = 1) +
  geom_vline(xintercept = cfg$key_weeks, linetype = "dotted") +
  annotate(
    "text", x = cfg$key_weeks, y = max(weekly$merged_events),
    label = paste("week", cfg$key_weeks), angle = 90, vjust = -0.3, hjust = 1, size = 3
  ) +
  annotate("text", x = label_wk, y = label_at("merged_events", label_wk) + 800,
           label = "total events", size = 3, hjust = 1.1) +
  annotate("text", x = label_wk, y = label_at("protest_theme_events", label_wk) + 800,
           label = "protest theme", size = 3, hjust = 1.1) +
  scale_x_continuous(breaks = scales::breaks_width(2)) +
  scale_y_continuous(
    name = "event count\n(total or protest theme)",
    sec.axis = sec_axis(~ . / scale_factor, name = paste("events matching", cfg$case_label))
  ) +
  labs(x = "ISO week in 2015") +
  theme_bw() +
  theme(
    axis.text.y.right  = element_text(colour = "darkred"),
    axis.title.y.right = element_text(colour = "darkred")
  )

# ---- 2. Weekly average tone --------------------------------------------------
# Point size shows how many events the weekly mean rests on; the early weeks
# have 1-3 events and are not reliable.
p_tone <- weekly |>
  drop_na(case_theme_avg_tone) |>
  ggplot(aes(iso_week, case_theme_avg_tone)) +
  geom_line(colour = "darkred", linewidth = 1) +
  geom_point(aes(size = case_theme_events), colour = "darkred") +
  geom_vline(xintercept = cfg$key_weeks, linetype = "dotted") +
  scale_x_continuous(breaks = scales::breaks_width(2)) +
  scale_size_area(name = "events in week") +
  labs(x = "ISO week in 2015", y = paste("average tone of", cfg$case_label)) +
  theme_bw() +
  theme(legend.position = "bottom")

# ---- 3. Maps -----------------------------------------------------------------
# GADM boundaries are downloaded once and cached in data/map/.
dir.create(cfg$map_dir, recursive = TRUE, showWarnings = FALSE)
country   <- st_as_sf(geodata::gadm("LBN", level = 0, path = cfg$map_dir))
districts <- st_as_sf(geodata::gadm("LBN", level = 2, path = cfg$map_dir))

# Country-level points (adm1 code "LE") are all geocoded to the national centroid
# and say nothing about where events happened, so they are dropped (paper, note 8).
points <- locations |>
  filter(geo_adm1_code != "LE") |>
  st_as_sf(coords = c("geo_long", "geo_lat"), crs = 4326, remove = FALSE)

# Each row of the mart already aggregates several events, so sum `events`
# per district rather than counting rows.
district_counts <- points |>
  st_join(districts["NAME_2"]) |>
  st_drop_geometry() |>
  group_by(NAME_2) |>
  summarise(n_events = sum(events), .groups = "drop")

bins <- c(0, 20, 100, 500, Inf)
bin_labels <- c("[0,20]", "(20,100]", "(100,500]", "(500+]")

districts <- districts |>
  left_join(district_counts, by = "NAME_2") |>
  mutate(
    n_events = replace_na(n_events, 0),
    n_bin = cut(n_events, breaks = bins, labels = bin_labels, include.lowest = TRUE)
  )

theme_map <- theme_bw() +
  theme(
    axis.line = element_blank(), axis.text = element_blank(),
    axis.title = element_blank(), axis.ticks = element_blank(),
    panel.grid = element_blank()
  )

p_country <- ggplot() +
  geom_sf(data = country, fill = "cornsilk") +
  geom_sf(data = districts, aes(fill = n_bin)) +
  scale_fill_manual(
    "",
    values = c("#4575b4", "#91bfdb", "#fc8d59", "#d73027") |> setNames(bin_labels)
  ) +
  theme_map +
  theme(legend.position = "bottom") +
  guides(fill = guide_legend(nrow = 2))

# Beirut inset: the largest point is the district centroid that GDELT uses when it
# only knows "Beirut", so it is reported in the label instead of plotted.
beirut <- districts |> filter(NAME_2 == "Beirut")
beirut_points <- points |> st_filter(beirut)
generic_n <- max(beirut_points$events)
beirut_points <- beirut_points |> filter(events != generic_n)

p_beirut <- ggplot() +
  geom_sf(data = districts, fill = "white") +
  geom_sf(data = beirut_points, colour = "darkred", size = 3) +
  geom_label_repel(
    data = beirut_points,
    aes(label = events, geometry = geometry),
    stat = "sf_coordinates", min.segment.length = 0, alpha = 0.7
  ) +
  annotate("text", x = -Inf, y = Inf, hjust = -0.1, vjust = 1.5,
           label = paste("generic points:", generic_n)) +
  coord_sf(xlim = c(35.46, 35.55), ylim = c(33.86, 33.92)) +
  theme_map

# ---- 4. Save -----------------------------------------------------------------
ggsave(file.path(cfg$fig_dir, "garbage_2015_counts.png"), p_counts, width = 8, height = 4.5, dpi = 200)
ggsave(file.path(cfg$fig_dir, "garbage_2015_tone.png"),   p_tone,   width = 8, height = 4.5, dpi = 200)
ggsave(file.path(cfg$fig_dir, "garbage_2015_map.png"),    p_country, width = 5, height = 7,  dpi = 200)
ggsave(file.path(cfg$fig_dir, "garbage_2015_beirut.png"), p_beirut,  width = 5, height = 5,  dpi = 200)
