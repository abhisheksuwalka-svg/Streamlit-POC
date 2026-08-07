"""
Export Snowflake data to bundled Parquet files for demo mode.

Run this ONCE against a Snowflake account that has the ARR model loaded. It writes
data/*.parquet, which lets the dashboard run with no Snowflake connection at all.

Usage:
    python3 scripts/export_demo_data.py

    # or with a different connection profile / warehouse
    SF_CONNECTION=myaccount SF_WAREHOUSE=ARR_WH python3 scripts/export_demo_data.py

Re-run this whenever the data model or sample data changes.

Author: Abhishek Suwalka
"""

import os
import sys
from decimal import Decimal

import pandas as pd
import snowflake.connector

# --- Connection settings (same env vars as app.py) ---
SF_CONNECTION = os.environ.get("SF_CONNECTION", "SPCS")
SF_DATABASE = os.environ.get("SF_DATABASE", "ARR_WAREHOUSE")
SF_SCHEMA = os.environ.get("SF_SCHEMA", "ARR_ANALYTICS")
SF_WAREHOUSE = os.environ.get("SF_WAREHOUSE", "AI_WH")
SF_ROLE = os.environ.get("SF_ROLE", "SYSADMIN")

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(REPO_ROOT, "data")

# Catalog metadata queries. These mirror the three INFORMATION_SCHEMA queries in
# app.py's Data Catalog tab, plus the extra columns those queries filter and sort
# on (TABLE_SCHEMA, ORDINAL_POSITION) which are needed but not displayed.
CATALOG_QUERIES = {
    "CATALOG_TABLES": f"""
        SELECT TABLE_SCHEMA, TABLE_TYPE, TABLE_NAME, ROW_COUNT, COMMENT
        FROM {SF_DATABASE}.INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = '{SF_SCHEMA}'
    """,
    "CATALOG_COLUMNS": f"""
        SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE,
               COLUMN_DEFAULT, COMMENT, ORDINAL_POSITION
        FROM {SF_DATABASE}.INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '{SF_SCHEMA}'
    """,
    "CATALOG_CONSTRAINTS": f"""
        SELECT TABLE_SCHEMA, TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE
        FROM {SF_DATABASE}.INFORMATION_SCHEMA.TABLE_CONSTRAINTS
        WHERE TABLE_SCHEMA = '{SF_SCHEMA}'
          AND CONSTRAINT_TYPE IN ('PRIMARY KEY', 'FOREIGN KEY')
    """,
}


def connect():
    params = {
        "connection_name": SF_CONNECTION,
        "database": SF_DATABASE,
        "schema": SF_SCHEMA,
        "warehouse": SF_WAREHOUSE,
    }
    if SF_ROLE:
        params["role"] = SF_ROLE
    return snowflake.connector.connect(**params)


def fetch(cur, query):
    """Run a query and return a DataFrame, matching app.py's run_query behaviour."""
    cur.execute(query)
    columns = [d[0] for d in cur.description]
    return pd.DataFrame(cur.fetchall(), columns=columns)


def normalise(df):
    """Convert Decimal columns to float64.

    Snowflake returns NUMBER as Decimal, which pandas holds as object dtype.
    Converting to float keeps demo-mode arithmetic and plotting identical to the
    live path and avoids Decimal/float mixing inside Plotly.
    """
    for col in df.columns:
        non_null = df[col].dropna()
        if len(non_null) and all(isinstance(v, Decimal) for v in non_null):
            df[col] = pd.to_numeric(df[col], errors="coerce")
    return df


def main():
    if not os.path.isdir(DATA_DIR):
        os.makedirs(DATA_DIR)
        print(f"Created {DATA_DIR}")

    print(f"Connecting via profile '{SF_CONNECTION}' ...")
    conn = connect()
    cur = conn.cursor()
    exported = []

    try:
        # Discover every table and view in the schema
        objects = fetch(cur, f"""
            SELECT TABLE_NAME, TABLE_TYPE
            FROM {SF_DATABASE}.INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = '{SF_SCHEMA}'
            ORDER BY TABLE_TYPE, TABLE_NAME
        """)
        if objects.empty:
            print(f"ERROR: no tables or views found in {SF_DATABASE}.{SF_SCHEMA}")
            return 1
        print(f"Found {len(objects)} objects to export\n")

        # Export each object
        for name in objects["TABLE_NAME"]:
            df = normalise(fetch(cur, f"SELECT * FROM {SF_DATABASE}.{SF_SCHEMA}.{name}"))
            path = os.path.join(DATA_DIR, f"{name}.parquet")
            df.to_parquet(path, index=False)
            exported.append((name, len(df), len(df.columns)))
            print(f"  {name:<32} {len(df):>5} rows  {len(df.columns):>3} cols")

        # Export catalog metadata
        print()
        for name, query in CATALOG_QUERIES.items():
            df = normalise(fetch(cur, query))
            path = os.path.join(DATA_DIR, f"{name}.parquet")
            df.to_parquet(path, index=False)
            exported.append((name, len(df), len(df.columns)))
            print(f"  {name:<32} {len(df):>5} rows  {len(df.columns):>3} cols")

    finally:
        cur.close()
        conn.close()

    total_rows = sum(r for _, r, _ in exported)
    total_bytes = sum(
        os.path.getsize(os.path.join(DATA_DIR, f))
        for f in os.listdir(DATA_DIR) if f.endswith(".parquet")
    )
    print(f"\nExported {len(exported)} files | {total_rows} rows | {total_bytes / 1024:.0f} KB")
    print(f"Location: {DATA_DIR}")
    print("\nTest it with:  SF_DEMO=1 streamlit run app.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
