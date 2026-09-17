"""
run_solutions.py

Runs SQLite-dialect equivalents of the 16 exercise queries in
sql/02_solutions.sql against the local flo_customers.db (built by
build_database.py) and prints each question with its result.

This exists purely for reproducibility: sql/02_solutions.sql is the
canonical MySQL answer key; this script re-implements the same logic
in SQLite syntax (julianday() instead of DATEDIFF(), || instead of
CONCAT(), strftime() instead of YEAR()) so anyone cloning the repo can
verify the answers with nothing but Python + pandas installed.

Usage:
    python scripts/build_database.py   # first time / to refresh
    python scripts/run_solutions.py
"""

import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "flo_customers.db"

# Comma-wrap the bracketed category list so LIKE '%,COCUK,%' can't be
# fooled by "AKTIFCOCUK" containing "COCUK" as a substring.
NORM_CATS = (
    "(',' || REPLACE(REPLACE(REPLACE("
    "interested_in_categories_12,'[',''),']',''),' ','') || ',')"
)
CATEGORIES = ["KADIN", "ERKEK", "COCUK", "AKTIFCOCUK", "AKTIFSPOR"]

QUERIES = [
    ("Q2", "Distinct customer count",
     "SELECT COUNT(DISTINCT master_id) AS musteri_sayisi FROM FLO;"),

    ("Q3", "Total orders & total revenue", """
        SELECT
            SUM(order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris_sayisi,
            SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS toplam_ciro
        FROM FLO;
    """),

    ("Q4", "Average revenue per order", """
        SELECT
            SUM(customer_value_total_ever_offline + customer_value_total_ever_online)
            / SUM(order_num_total_ever_online + order_num_total_ever_offline) AS alisveris_basi_ort_ciro
        FROM FLO;
    """),

    ("Q5", "Orders & revenue by last_order_channel", """
        SELECT last_order_channel,
            SUM(order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris,
            SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS toplam_ciro
        FROM FLO
        GROUP BY last_order_channel
        ORDER BY toplam_ciro DESC;
    """),

    ("Q6", "Revenue by store_type", """
        SELECT store_type,
            SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS toplam_ciro
        FROM FLO
        GROUP BY store_type
        ORDER BY toplam_ciro DESC;
    """),

    ("Q7", "Order counts by first_order_date year", """
        SELECT CAST(strftime('%Y', first_order_date) AS INTEGER) AS yil,
            SUM(order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris
        FROM FLO
        GROUP BY yil
        ORDER BY yil;
    """),

    ("Q8", "Average revenue per order by last_order_channel", """
        SELECT last_order_channel,
            SUM(customer_value_total_ever_offline + customer_value_total_ever_online) /
            SUM(order_num_total_ever_online + order_num_total_ever_offline) AS ort_ciro_alisveris_basi
        FROM FLO
        GROUP BY last_order_channel
        ORDER BY ort_ciro_alisveris_basi DESC;
    """),

    ("Q9", "Most popular category (last 12 months), all ranked", " UNION ALL ".join(
        f"SELECT '{c}' AS kategori, COUNT(*) AS musteri_sayisi FROM FLO WHERE {NORM_CATS} LIKE '%,{c},%'"
        for c in CATEGORIES
    ) + " ORDER BY musteri_sayisi DESC;"),

    ("Q10", "Most preferred store_type", """
        SELECT store_type, COUNT(*) AS musteri_sayisi
        FROM FLO
        GROUP BY store_type
        ORDER BY musteri_sayisi DESC
        LIMIT 1;
    """),

    ("Q11", "Top category per last_order_channel", f"""
        WITH cat_counts AS (
            {" UNION ALL ".join(
                f"SELECT last_order_channel, '{c}' AS kategori, COUNT(*) AS musteri_sayisi "
                f"FROM FLO WHERE {NORM_CATS} LIKE '%,{c},%' GROUP BY last_order_channel"
                for c in CATEGORIES
            )}
        ),
        ranked AS (
            SELECT *, RANK() OVER (PARTITION BY last_order_channel ORDER BY musteri_sayisi DESC) AS rnk
            FROM cat_counts
        )
        SELECT last_order_channel, kategori, musteri_sayisi
        FROM ranked WHERE rnk = 1
        ORDER BY last_order_channel;
    """),

    ("Q12", "Customer with the most total orders", """
        SELECT master_id,
            (order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris
        FROM FLO
        ORDER BY toplam_alisveris DESC
        LIMIT 1;
    """),

    ("Q13", "Top customer: avg revenue/order & purchase frequency (days)", """
        SELECT master_id,
            (order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris,
            (customer_value_total_ever_offline + customer_value_total_ever_online) /
                (order_num_total_ever_online + order_num_total_ever_offline) AS alisveris_basi_ort_ciro,
            (julianday(last_order_date) - julianday(first_order_date)) /
                (order_num_total_ever_online + order_num_total_ever_offline) AS ort_alisveris_sikligi_gun
        FROM FLO
        ORDER BY toplam_alisveris DESC
        LIMIT 1;
    """),

    ("Q14", "Top 100 by revenue: avg purchase frequency (days)", """
        WITH top100 AS (
            SELECT
                (julianday(last_order_date) - julianday(first_order_date)) /
                    (order_num_total_ever_online + order_num_total_ever_offline) AS sikligi
            FROM FLO
            ORDER BY (customer_value_total_ever_offline + customer_value_total_ever_online) DESC
            LIMIT 100
        )
        SELECT AVG(sikligi) AS ilk100_ort_alisveris_sikligi_gun FROM top100;
    """),

    ("Q15", "Top customer per last_order_channel", """
        WITH ranked AS (
            SELECT master_id, last_order_channel,
                (order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris,
                RANK() OVER (PARTITION BY last_order_channel
                             ORDER BY (order_num_total_ever_online + order_num_total_ever_offline) DESC) AS rnk
            FROM FLO
        )
        SELECT last_order_channel, master_id, toplam_alisveris
        FROM ranked WHERE rnk = 1
        ORDER BY last_order_channel;
    """),

    ("Q16", "Most recent purchaser(s) — ties included", """
        SELECT master_id, last_order_date
        FROM FLO
        WHERE last_order_date = (SELECT MAX(last_order_date) FROM FLO)
        ORDER BY master_id;
    """),
]


def main() -> None:
    if not DB_PATH.exists():
        raise SystemExit(
            f"{DB_PATH.name} not found — run 'python scripts/build_database.py' first."
        )

    with sqlite3.connect(DB_PATH) as conn:
        for number, title, query in QUERIES:
            print("=" * 78)
            print(f"{number}. {title}")
            print("-" * 78)
            result = pd.read_sql_query(query, conn)
            with pd.option_context("display.max_rows", 20, "display.width", 100):
                print(result.to_string(index=False))
            print()


if __name__ == "__main__":
    main()
