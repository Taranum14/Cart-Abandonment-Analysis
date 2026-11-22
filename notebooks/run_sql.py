"""Run a .sql file against the cleaned database and print every result.

Usage (from the project root):
    python notebooks/run_sql.py sql/02_funnel.sql

Each query's result is printed and also saved to data/processed/results/
as a CSV, which you can load straight into Power BI or Tableau.
"""
import sys
from pathlib import Path

import duckdb
import pandas as pd

pd.set_option("display.width", 200)
pd.set_option("display.max_columns", 20)

sql_file = Path(sys.argv[1])
con = duckdb.connect("data/processed/cart.duckdb")
out_dir = Path("data/processed/results")
out_dir.mkdir(parents=True, exist_ok=True)

statements = [s.strip() for s in sql_file.read_text().split(";") if s.strip()]
for i, stmt in enumerate(statements, start=1):
    result = con.execute(stmt)
    try:
        df = result.fetchdf()
    except Exception:
        continue  # statements like CREATE TABLE return no rows
    name = f"{sql_file.stem}_q{i}.csv"
    df.to_csv(out_dir / name, index=False)
    print(f"\n--- {name} ---")
    print(df.head(15).to_string(index=False))
