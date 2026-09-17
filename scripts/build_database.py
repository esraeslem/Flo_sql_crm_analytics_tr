"""
build_database.py

Loads data/flo_data_20K.csv into a local SQLite database
(flo_customers.db) with a schema mirroring sql/01_schema.sql, so the
16 exercise queries can be run and verified end-to-end without a MySQL
server. This is a reproducibility aid for the portfolio, not a
replacement for the MySQL schema in sql/01_schema.sql.

Usage:
    python scripts/build_database.py
"""

import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "data" / "flo_data_20K.csv"
DB_PATH = ROOT / "flo_customers.db"

SCHEMA = """
DROP TABLE IF EXISTS FLO;
CREATE TABLE FLO (
    master_id                          TEXT PRIMARY KEY,
    order_channel                      TEXT,
    last_order_channel                 TEXT,
    first_order_date                   TEXT,
    last_order_date                    TEXT,
    last_order_date_online             TEXT,
    last_order_date_offline            TEXT,
    order_num_total_ever_online        REAL,
    order_num_total_ever_offline       REAL,
    customer_value_total_ever_offline  REAL,
    customer_value_total_ever_online   REAL,
    interested_in_categories_12        TEXT,
    store_type                         TEXT
);
"""


def build_database() -> None:
    df = pd.read_csv(CSV_PATH)

    with sqlite3.connect(DB_PATH) as conn:
        conn.executescript(SCHEMA)
        df.to_sql("FLO", conn, if_exists="append", index=False)
        row_count = conn.execute("SELECT COUNT(*) FROM FLO").fetchone()[0]

    print(f"Loaded {row_count:,} rows into {DB_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    build_database()
