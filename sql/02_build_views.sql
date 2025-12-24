-- 2) Checks (run after Python loads data)
-- =========================================

-- 1) Order Status Distribution
SELECT order_status, COUNT(*) AS n
FROM orders
GROUP BY order_status
ORDER BY n DESC;

-- 2) Check
SELECT
  SUM(price IS NULL) AS price_missing,
  SUM(price <= 0) AS price_nonpositive,
  SUM(freight_value IS NULL) AS freight_missing,
  SUM(freight_value < 0) AS freight_negative
FROM order_items;

-- 3) Missing Date Fields (Delivered Order Related Dates)
SELECT
  SUM(order_purchase_timestamp IS NULL) AS purchase_missing,
  SUM(order_delivered_customer_date IS NULL) AS delivered_missing
FROM orders
WHERE order_status = 'delivered';

-- =========================
-- 3) Views (your original)
-- =========================

DROP VIEW IF EXISTS vw_sales_fact;
CREATE VIEW vw_sales_fact AS
SELECT
  -- Grain: order_item
  oi.order_id,
  oi.order_item_id,

  -- Keys
  o.customer_id,
  c.customer_unique_id,
  oi.product_id,
  oi.seller_id,

  -- Dates
  o.order_status,
  o.order_purchase_timestamp,
  o.order_approved_at,
  o.order_delivered_carrier_date,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,

  -- Measures
  oi.price AS item_price,
  oi.freight_value AS item_freight,

  -- Product/category
  p.product_category_name AS category_pt,
  COALESCE(ct.product_category_name_english, 'Unknown') AS category_en,

  -- Customer location
  c.customer_city,
  c.customer_state,
  c.customer_zip_code_prefix,

  -- Review (order level; repeated per item)
  r.review_score,

  -- Delivery metrics (days)
  CASE
    WHEN o.order_delivered_customer_date IS NOT NULL
     AND o.order_purchase_timestamp IS NOT NULL
    THEN TIMESTAMPDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)
    ELSE NULL
  END AS days_to_deliver,

  CASE
    WHEN o.order_estimated_delivery_date IS NOT NULL
     AND o.order_delivered_customer_date IS NOT NULL
    THEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)
    ELSE NULL
  END AS days_vs_estimated

FROM order_items oi
JOIN orders o
  ON o.order_id = oi.order_id
LEFT JOIN products p
  ON p.product_id = oi.product_id
LEFT JOIN category_translation ct
  ON ct.product_category_name = p.product_category_name
LEFT JOIN customers c
  ON c.customer_id = o.customer_id
LEFT JOIN order_reviews r
  ON r.order_id = o.order_id

-- Business rule: delivered only + positive price
WHERE o.order_status = 'delivered'
  AND oi.price > 0;

SELECT COUNT(*) AS n_rows FROM vw_sales_fact;
SELECT MIN(order_purchase_timestamp) AS min_dt, MAX(order_purchase_timestamp) AS max_dt FROM vw_sales_fact;

SELECT category_en, COUNT(*) AS n
FROM vw_sales_fact
GROUP BY category_en
ORDER BY n DESC
LIMIT 15;

DROP VIEW IF EXISTS fact_sales;
CREATE VIEW fact_sales AS
SELECT
  order_id,
  order_item_id,
  customer_id,
  product_id,
  seller_id,
  DATE(order_purchase_timestamp) AS order_date,
  item_price,
  item_freight,
  review_score,
  days_to_deliver,
  days_vs_estimated
FROM vw_sales_fact;

DROP VIEW IF EXISTS dim_customer;
CREATE VIEW dim_customer AS
SELECT
  customer_id,
  customer_unique_id,
  customer_city,
  customer_state,
  customer_zip_code_prefix
FROM customers;

DROP VIEW IF EXISTS dim_product;
CREATE VIEW dim_product AS
SELECT
  p.product_id,
  p.product_category_name AS category_pt,
  COALESCE(ct.product_category_name_english, 'Unknown') AS category_en
FROM products p
LEFT JOIN category_translation ct
  ON ct.product_category_name = p.product_category_name;

DROP VIEW IF EXISTS dim_seller;
CREATE VIEW dim_seller AS
SELECT
  seller_id,
  seller_city,
  seller_state,
  seller_zip_code_prefix
FROM sellers;

DROP VIEW IF EXISTS dim_geo;
CREATE VIEW dim_geo AS
SELECT
  geolocation_zip_code_prefix AS zip_code_prefix,
  AVG(geolocation_lat) AS lat,
  AVG(geolocation_lng) AS lng
FROM geolocation_raw
GROUP BY geolocation_zip_code_prefix;

-- Final sanity checks
SELECT COUNT(*) AS fact_rows FROM fact_sales;
SELECT COUNT(*) AS n, COUNT(DISTINCT customer_id) AS n_distinct FROM dim_customer;
SELECT COUNT(*) AS n, COUNT(DISTINCT product_id) AS n_distinct FROM dim_product;
SELECT COUNT(*) AS n, COUNT(DISTINCT seller_id) AS n_distinct FROM dim_seller;
SELECT MIN(order_date) AS min_dt, MAX(order_date) AS max_dt FROM fact_sales;