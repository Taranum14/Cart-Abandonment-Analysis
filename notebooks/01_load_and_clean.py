"""Load the clickstream CSV into DuckDB and clean it.

Usage:
    python notebooks/01_load_and_clean.py data/raw/2019-Nov.csv

Creates data/processed/cart.duckdb with a cleaned `events` table.
"""
import sys
from pathlib import Path

import duckdb

csv_path = Path(sys.argv[1])
out_dir = Path("data/processed")
out_dir.mkdir(parents=True, exist_ok=True)

con = duckdb.connect(str(out_dir / "cart.duckdb"))

con.execute(
    """
    CREATE OR REPLACE TABLE events AS
    SELECT DISTINCT
        CAST(event_time AS TIMESTAMP) AS event_time,
        event_type,
        product_id,
        category_code,
        COALESCE(split_part(category_code, '.', 1), 'unknown') AS category,
        COALESCE(brand, 'unknown') AS brand,
        price,
        user_id,
        user_session
    FROM read_csv_auto(?, header = true)
    WHERE price > 0
      AND user_session IS NOT NULL
      AND event_type IN ('view', 'cart', 'remove_from_cart', 'purchase')
    """,
    [str(csv_path)],
)

print(con.execute("SELECT COUNT(*) AS rows FROM events").fetchdf())
print(con.execute("SELECT event_type, COUNT(*) AS n FROM events GROUP BY 1 ORDER BY 2 DESC").fetchdf())
