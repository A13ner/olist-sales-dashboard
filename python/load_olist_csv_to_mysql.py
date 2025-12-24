#%% =========================================
# Olist BI Project - Import 9 CSVs into MySQL
# Works on: Windows + MySQL 8.0 + Spyder
# Requires: pandas, sqlalchemy, pymysql
# Notes:
#   1) Run Create_table.sql FIRST to create tables
#   2) Set MYSQL_PASSWORD as an environment variable (do NOT hardcode)
#   3) Set OLIST_DATA_DIR to your folder containing the 9 CSV files
# ===========================================

import os
import pandas as pd
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus

#%% ============== 1) CONFIG ==============

MYSQL_HOST = os.getenv("MYSQL_HOST", "127.0.0.1")
MYSQL_PORT = int(os.getenv("MYSQL_PORT", "3307"))
MYSQL_USER = os.getenv("MYSQL_USER", "bi_user")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")  # do NOT hardcode
MYSQL_DB = os.getenv("MYSQL_DB", "olist_bi")

# Folder that contains the CSVs (set this!)
DATA_DIR = os.getenv("OLIST_DATA_DIR", r"C:\path\to\olist_csvs")  # <-- change me

if not MYSQL_PASSWORD:
    raise ValueError("MYSQL_PASSWORD is not set. Please set it as an environment variable.")

if not os.path.isdir(DATA_DIR):
    raise ValueError(f"DATA_DIR not found: {DATA_DIR}. Please set OLIST_DATA_DIR or edit DATA_DIR.")

#%% ============== 2) CREATE ENGINE ==============

pw = quote_plus(MYSQL_PASSWORD)
engine = create_engine(
    f"mysql+pymysql://{MYSQL_USER}:{pw}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}?charset=utf8mb4",
    pool_pre_ping=True
)

# Quick connection test
with engine.connect() as conn:
    conn.execute(text("SELECT 1;"))
print("✅ MySQL connected")

#%% ============== 3) TABLE CONFIG ==============

TABLES = [
    {
        "table": "category_translation",
        "file": "product_category_name_translation.csv",
        "cols": ["product_category_name", "product_category_name_english"],
        "date_cols": [],
        "num_cols": [],
        "text_cleanup_cols": []
    },
    {
        "table": "customers",
        "file": "olist_customers_dataset.csv",
        "cols": ["customer_id", "customer_unique_id", "customer_zip_code_prefix", "customer_city", "customer_state"],
        "date_cols": [],
        "num_cols": [],
        "text_cleanup_cols": []
    },
    {
        "table": "geolocation_raw",
        "file": "olist_geolocation_dataset.csv",
        "cols": ["geolocation_zip_code_prefix", "geolocation_lat", "geolocation_lng", "geolocation_city", "geolocation_state"],
        "date_cols": [],
        "num_cols": ["geolocation_lat", "geolocation_lng"],
        "text_cleanup_cols": []
    },
    {
        "table": "orders",
        "file": "olist_orders_dataset.csv",
        "cols": ["order_id", "customer_id", "order_status",
                 "order_purchase_timestamp", "order_approved_at",
                 "order_delivered_carrier_date", "order_delivered_customer_date",
                 "order_estimated_delivery_date"],
        "date_cols": ["order_purchase_timestamp", "order_approved_at",
                      "order_delivered_carrier_date", "order_delivered_customer_date",
                      "order_estimated_delivery_date"],
        "num_cols": [],
        "text_cleanup_cols": []
    },
    {
        "table": "order_items",
        "file": "olist_order_items_dataset.csv",
        "cols": ["order_id", "order_item_id", "product_id", "seller_id",
                 "shipping_limit_date", "price", "freight_value"],
        "date_cols": ["shipping_limit_date"],
        "num_cols": ["order_item_id", "price", "freight_value"],
        "text_cleanup_cols": []
    },
    {
        "table": "order_payments",
        "file": "olist_order_payments_dataset.csv",
        "cols": ["order_id", "payment_sequential", "payment_type", "payment_installments", "payment_value"],
        "date_cols": [],
        "num_cols": ["payment_sequential", "payment_installments", "payment_value"],
        "text_cleanup_cols": []
    },
    {
        "table": "order_reviews",
        "file": "olist_order_reviews_dataset.csv",
        "cols": ["review_id", "order_id", "review_score",
                 "review_comment_title", "review_comment_message",
                 "review_creation_date", "review_answer_timestamp"],
        "date_cols": ["review_creation_date", "review_answer_timestamp"],
        "num_cols": ["review_score"],
        "text_cleanup_cols": ["review_comment_title", "review_comment_message"]
    },
    {
        "table": "products",
        "file": "olist_products_dataset.csv",
        "cols": ["product_id", "product_category_name",
                 "product_name_lenght", "product_description_lenght",
                 "product_photos_qty", "product_weight_g",
                 "product_length_cm", "product_height_cm", "product_width_cm"],
        "date_cols": [],
        "num_cols": ["product_name_lenght", "product_description_lenght", "product_photos_qty",
                     "product_weight_g", "product_length_cm", "product_height_cm", "product_width_cm"],
        "text_cleanup_cols": []
    },
    {
        "table": "sellers",
        "file": "olist_sellers_dataset.csv",
        "cols": ["seller_id", "seller_zip_code_prefix", "seller_city", "seller_state"],
        "date_cols": [],
        "num_cols": [],
        "text_cleanup_cols": []
    },
]

#%% ============== 4) HELPERS =================

def read_csv_robust(path: str):
    """Try utf-8 first; fallback to latin1 for Portuguese accents."""
    try:
        df = pd.read_csv(path, encoding="utf-8", dtype=str, keep_default_na=False)
        return df, "utf-8"
    except UnicodeDecodeError:
        df = pd.read_csv(path, encoding="latin1", dtype=str, keep_default_na=False)
        return df, "latin1"

def clean_and_cast(df: pd.DataFrame, cfg: dict) -> pd.DataFrame:
    """Select columns, normalize blanks to NULL, cast numeric/datetime columns."""
    df = df[cfg["cols"]].copy()

    # Convert blank strings to None for MySQL NULL
    df = df.replace({"": None})

    # Clean text columns: remove embedded newlines (important for reviews)
    for col in cfg["text_cleanup_cols"]:
        if col in df.columns:
            df[col] = (df[col].astype(str)
                       .str.replace("\r", " ", regex=False)
                       .str.replace("\n", " ", regex=False))

    # Convert numeric columns
    for col in cfg["num_cols"]:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    # Convert datetime columns
    for col in cfg["date_cols"]:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], errors="coerce")

    # Replace NaN/NaT with None
    df = df.where(pd.notnull(df), None)
    return df

#%% ============== 5) IMPORT LOOP =============

for cfg in TABLES:
    table = cfg["table"]
    filename = cfg["file"]
    path = os.path.join(DATA_DIR, filename)

    if not os.path.exists(path):
        print(f"❌ Missing file: {path}")
        continue

    df_raw, enc = read_csv_robust(path)
    df = clean_and_cast(df_raw, cfg)

    print(f"➡️ Loading {filename} -> {table} | encoding={enc} | shape={df.shape}")

    # Clear table before loading to avoid duplicates
    try:
        with engine.begin() as conn:
            conn.execute(text(f"TRUNCATE TABLE `{table}`;"))
    except Exception as e:
        raise RuntimeError(
            f"TRUNCATE failed for `{table}`. Make sure tables are created first (run Create_table.sql).\n"
            f"Original error: {e}"
        )

    # Insert in chunks
    df.to_sql(
        name=table,
        con=engine,
        if_exists="append",
        index=False,
        chunksize=5000,
        method="multi"
    )

    # Verify row count
    with engine.connect() as conn:
        n = conn.execute(text(f"SELECT COUNT(*) FROM `{table}`;")).scalar()
    print(f"✅ Done: {table} rows={n}\n")

print("🎉 All available tables imported.")
