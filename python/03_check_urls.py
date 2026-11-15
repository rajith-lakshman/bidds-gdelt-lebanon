"""Check which article URLs for the key weeks are still live
(Python version of r/03_check_urls.R; paper Annexe A step 5).

Input : data/sample/fct_case_event_urls.csv (one row per url x ISO week)
Output: data/url_check.csv (git-ignored). Same file and columns as the R script,
        so a cache written by either language is reused by the other.
Requires: pandas, httpx.
"""
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import httpx
import pandas as pd

import config as cfg

CACHE = cfg.ROOT / "data" / "url_check.csv"
KEYWORDS = r"garbage|stink|waste|trash|rubbish|sukleen|naameh"

urls = pd.read_csv(cfg.SAMPLE_DIR / "fct_case_event_urls.csv")
urls = urls[urls["iso_week"].isin(cfg.KEY_WEEKS)]

done = pd.read_csv(CACHE) if CACHE.exists() else pd.DataFrame(columns=["url", "status", "final_url", "error"])
todo = [u for u in urls["url"].drop_duplicates() if u not in set(done["url"])]
print(f"{len(todo)} URLs to check ({urls['url'].nunique() - len(todo)} already cached)")


def check_one(client: httpx.Client, url: str) -> dict:
    try:
        r = client.get(url)
        return {"url": url, "status": r.status_code, "final_url": str(r.url), "error": None}
    except Exception as e:  # network errors, timeouts, bad certificates
        return {"url": url, "status": None, "final_url": None, "error": f"{type(e).__name__}: {e}"}


if todo:
    with httpx.Client(
        follow_redirects=True,
        timeout=10,
        headers={"User-Agent": "bidds-gdelt-lebanon url check (research)"},
    ) as client, ThreadPoolExecutor(max_workers=10) as pool:
        new = pd.DataFrame(pool.map(lambda u: check_one(client, u), todo))
    done = pd.concat([done, new], ignore_index=True)
    done.to_csv(CACHE, index=False, na_rep="NA")  # "NA" matches what readr writes

# A URL counts as live if it returns 200 and did not redirect to a bare homepage,
# which is how most expired news links resolve.
result = urls.merge(done, on="url", how="left")
result["homepage"] = result["final_url"].str.match(r"^https?://[^/]+/?$", na=False)
result["live"] = (result["status"] == 200) & ~result["homepage"]
# Annexe A step 6: keyword hit in the URL itself, usable even when the page is gone
result["keyword_in_url"] = result["url"].str.lower().str.contains(KEYWORDS, regex=True)

summary = (
    result.groupby("iso_week")
    .agg(urls=("url", "size"), live=("live", "sum"),
         live_share=("live", "mean"), keyword_in_url=("keyword_in_url", "sum"))
    .reset_index()
)
print(summary.to_string(index=False))
