"""Export the dbt marts to small CSV files in data/sample/."""
import os
from pathlib import Path

from google.cloud import bigquery

PROJECT = os.environ.get("GCP_PROJECT_ID")  # falls back to the gcloud default
DATASET = os.environ.get("BQ_DATASET", "bidds_gdelt_dev")
OUT = Path(__file__).resolve().parents[1] / "data" / "sample"
TABLES = ["fct_weekly_counts", "fct_case_event_locations", "fct_case_event_urls"]

client = bigquery.Client(project=PROJECT)
OUT.mkdir(parents=True, exist_ok=True)

for table in TABLES:
    df = client.query(f"select * from `{client.project}.{DATASET}.{table}`").to_dataframe()
    df.to_csv(OUT / f"{table}.csv", index=False)
    print(f"{table}: {len(df)} rows")
