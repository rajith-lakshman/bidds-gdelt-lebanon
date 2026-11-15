"""Weekly counts, weekly tone and maps for the Garbage Crisis 2015
(Python version of r/02_plots.R; paper Figure 3.1).

Reads the dbt marts exported to data/sample/ (see python/export_marts.py).
Requires: pandas, numpy, matplotlib, geopandas, adjustText.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import geopandas as gpd
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from adjustText import adjust_text
from matplotlib.lines import Line2D
from matplotlib.patches import Patch

import config as cfg

plt.switch_backend("Agg")  # write files only; no pop-up windows

weekly = pd.read_csv(cfg.SAMPLE_DIR / "fct_weekly_counts.csv")
locations = pd.read_csv(cfg.SAMPLE_DIR / "fct_case_event_locations.csv")

# ---- 1. Weekly counts -------------------------------------------------------
# Grey areas: all merged events and events whose articles carry the PROTEST theme.
# Red line: events whose articles carry the case theme, on a secondary axis.
scale = weekly["merged_events"].max() / weekly["case_theme_events"].max()
peak = weekly.loc[weekly["merged_events"].idxmax()]
ymax = weekly["merged_events"].max()

fig, ax = plt.subplots(figsize=(8, 4.5))
ax.fill_between(weekly["iso_week"], weekly["merged_events"], color="0.7", linewidth=0)
ax.fill_between(weekly["iso_week"], weekly["protest_theme_events"], color="0.88", linewidth=0)
ax.plot(weekly["iso_week"], weekly["case_theme_events"] * scale, color="darkred", linewidth=2)

for wk in cfg.KEY_WEEKS:
    ax.axvline(wk, linestyle=":", color="black", linewidth=1)
    ax.text(wk - 0.15, ymax * 1.02, f"week {wk}", rotation=90, ha="right", va="top", fontsize=8)

ax.text(peak["iso_week"] - 0.3, peak["merged_events"] + 300, "total events", ha="right", fontsize=8)
ax.text(peak["iso_week"] - 0.3, peak["protest_theme_events"] + 300, "protest theme", ha="right", fontsize=8)

secondary = ax.secondary_yaxis("right", functions=(lambda y: y / scale, lambda y: y * scale))
secondary.set_ylabel(f"events matching {cfg.CASE_LABEL}", color="darkred")
secondary.tick_params(axis="y", colors="darkred")

ax.set_xticks(range(int(weekly["iso_week"].min()), int(weekly["iso_week"].max()) + 1, 2))
ax.set_xlabel("ISO week in 2015")
ax.set_ylabel("event count\n(total or protest theme)")
ax.set_ylim(0, ymax * 1.08)
fig.tight_layout()
fig.savefig(cfg.FIG_DIR / "py_garbage_2015_counts.png", dpi=200)
plt.close(fig)

# ---- 2. Weekly average tone -------------------------------------------------
# Marker area shows how many events the weekly mean rests on; the early weeks
# have 1-3 events and are not reliable.
tone = weekly.dropna(subset=["case_theme_avg_tone"])

fig, ax = plt.subplots(figsize=(8, 4.5))
ax.plot(tone["iso_week"], tone["case_theme_avg_tone"], color="darkred", linewidth=2)
ax.scatter(tone["iso_week"], tone["case_theme_avg_tone"],
           s=tone["case_theme_events"] * 1.5, color="darkred", zorder=3)
for wk in cfg.KEY_WEEKS:
    ax.axvline(wk, linestyle=":", color="black", linewidth=1)

handles = [Line2D([], [], marker="o", linestyle="", color="darkred", markersize=np.sqrt(n * 1.5), label=str(n))
           for n in (10, 50, 150)]
ax.legend(handles=handles, title="events in week", loc="upper center",
          bbox_to_anchor=(0.5, -0.15), ncol=3, frameon=False)
ax.set_xticks(range(int(weekly["iso_week"].min()), int(weekly["iso_week"].max()) + 1, 2))
ax.set_xlabel("ISO week in 2015")
ax.set_ylabel(f"average tone of {cfg.CASE_LABEL}")
fig.tight_layout()
fig.savefig(cfg.FIG_DIR / "py_garbage_2015_tone.png", dpi=200)
plt.close(fig)

# ---- 3. Maps ----------------------------------------------------------------
gadm = cfg.ensure_gadm()
country = gpd.read_file(gadm, layer="ADM_ADM_0")
districts = gpd.read_file(gadm, layer="ADM_ADM_2")[["NAME_2", "geometry"]]

# Country-level points (adm1 code "LE") are all geocoded to the national centroid
# and say nothing about where events happened, so they are dropped (paper, note 8).
loc = locations[locations["geo_adm1_code"] != "LE"]
points = gpd.GeoDataFrame(
    loc, geometry=gpd.points_from_xy(loc["geo_long"], loc["geo_lat"]), crs=4326
)

# Each mart row already aggregates several events, so sum `events` per district
# rather than counting rows.
joined = gpd.sjoin(points, districts, how="left", predicate="within")
unmatched = int(joined.loc[joined["NAME_2"].isna(), "events"].sum())
if unmatched:
    print(f"Note: {unmatched} events fall outside every district polygon and are not mapped")

counts = joined.groupby("NAME_2", as_index=False)["events"].sum().rename(columns={"events": "n_events"})
districts = districts.merge(counts, on="NAME_2", how="left")
districts["n_events"] = districts["n_events"].fillna(0)

bin_labels = ["[0,20]", "(20,100]", "(100,500]", "(500+]"]
bin_colours = dict(zip(bin_labels, ["#4575b4", "#91bfdb", "#fc8d59", "#d73027"]))
districts["n_bin"] = pd.cut(districts["n_events"], bins=[0, 20, 100, 500, np.inf],
                            labels=bin_labels, include_lowest=True)

fig, ax = plt.subplots(figsize=(5, 7))
country.plot(ax=ax, color="cornsilk", edgecolor="grey", linewidth=0.5)
districts.plot(ax=ax, color=districts["n_bin"].astype(str).map(bin_colours),
               edgecolor="grey", linewidth=0.3)
ax.legend(handles=[Patch(facecolor=c, label=l) for l, c in bin_colours.items()],
          loc="upper center", bbox_to_anchor=(0.5, 0.0), ncol=2, frameon=False)
ax.set_axis_off()
fig.tight_layout()
fig.savefig(cfg.FIG_DIR / "py_garbage_2015_map.png", dpi=200)
plt.close(fig)

# Beirut inset: the largest point is the district centroid that GDELT uses when it
# only knows "Beirut", so it is reported in the label instead of plotted.
beirut = districts[districts["NAME_2"] == "Beirut"]
beirut_points = gpd.sjoin(points, beirut[["geometry"]], how="inner", predicate="within")
generic_n = int(beirut_points["events"].max())
beirut_points = beirut_points[beirut_points["events"] != generic_n]

# Points that share exact coordinates (GDELT geocodes several place names to the same
# spot) would draw on top of each other, so they get one combined label.
beirut_labels = (
    beirut_points.groupby(["geo_long", "geo_lat"])["events"]
    .agg(lambda s: " / ".join(str(v) for v in s))
    .reset_index(name="label")
)

fig, ax = plt.subplots(figsize=(5, 5))
districts.plot(ax=ax, color="white", edgecolor="grey", linewidth=0.5)
ax.scatter(beirut_labels["geo_long"], beirut_labels["geo_lat"], color="darkred", s=30, zorder=3)
# Fix the window and aspect before placing labels, otherwise adjustText works on stale limits
ax.set_xlim(35.46, 35.55)
ax.set_ylim(33.86, 33.92)
ax.set_aspect(1 / np.cos(np.radians(33.89)), adjustable="box")
texts = [ax.text(r.geo_long, r.geo_lat, r.label, fontsize=9, fontweight="bold",
                 bbox=dict(boxstyle="round,pad=0.2", fc="white", alpha=0.7))
         for r in beirut_labels.itertuples()]
adjust_text(texts, x=beirut_labels["geo_long"].values, y=beirut_labels["geo_lat"].values,
            ax=ax, arrowprops=dict(arrowstyle="-", color="grey"))
ax.text(0.02, 0.98, f"generic points: {generic_n}", transform=ax.transAxes, va="top")
ax.set_axis_off()
fig.tight_layout()
fig.savefig(cfg.FIG_DIR / "py_garbage_2015_beirut.png", dpi=200)
plt.close(fig)

print("Saved 4 figures to", cfg.FIG_DIR)
