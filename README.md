# Olist Sales Performance Dashboard (Power BI + MySQL)

A portfolio project that builds a simple BI pipeline using the Olist e-commerce dataset:
MySQL for storage + SQL views for modeling + Power BI for visualization.

![Dashboard Overview](assets/dashboard_overview.png)

## Tech Stack
- MySQL 8.0
- Python (pandas, sqlalchemy, pymysql)
- Power BI Desktop

## Dataset
Olist Brazilian E-Commerce Public Dataset (available on Kaggle).

## Project Structure
- `sql/` MySQL table schema + BI views
- `python/` CSV-to-MySQL loader script
- `powerbi/` Power BI report (`.pbix`) and exported PDF
- `assets/` screenshots

## How to Reproduce (Local)
1. Create tables in MySQL  
   Run: `sql/Create_table.sql`

2. Load CSVs into MySQL  
   Run: `python/load_olist_csv_to_mysql.py`  
   Set env vars before running:
   - `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DB`

3. Create BI views  
   Run: `sql/olist_bi_build.sql`

4. Open Power BI
- Open `powerbi/olist_sales_dashboard.pbix`
- Update data source if needed, then click Refresh

## Dashboard Highlights
- Revenue / Orders / AOV / On-time rate / Avg delivery days
- Revenue trend (monthly)
- Top categories & top states by revenue
- New vs Returning customers and retention rate
