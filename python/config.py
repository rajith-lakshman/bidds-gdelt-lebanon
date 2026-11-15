"""Shared settings for the Python scripts (mirror of r/config.R)."""
import os
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# BigQuery location of the dbt marts (same variables as python/export_marts.py)
PROJECT = os.environ.get("GCP_PROJECT_ID")  # None falls back to your gcloud default project
DATASET = os.environ.get("BQ_DATASET", "bidds_gdelt_dev")

SAMPLE_DIR = ROOT / "data" / "sample"
MAP_DIR = ROOT / "data" / "map" / "gadm"   # git-ignored via data/*
FIG_DIR = ROOT / "docs" / "figures"

# Case-study settings (Garbage Crisis 2015, paper section 3.1)
CASE_LABEL = "WB_1797_SOLID_WASTE"
KEY_WEEKS = [29, 31, 35]                   # ISO weeks the paper discusses

GADM_URL = "https://geodata.ucdavis.edu/gadm/gadm4.1/gpkg/gadm41_LBN.gpkg"
GADM_PATH = MAP_DIR / "gadm41_LBN.gpkg"

FIG_DIR.mkdir(parents=True, exist_ok=True)


def ensure_gadm() -> Path:
    """Download the GADM 4.1 Lebanon GeoPackage once and cache it."""
    if not GADM_PATH.exists():
        MAP_DIR.mkdir(parents=True, exist_ok=True)
        urllib.request.urlretrieve(GADM_URL, GADM_PATH)
    return GADM_PATH
