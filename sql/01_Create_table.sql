-- ============================================================
-- Olist BI - Build Schema + Tables + Views (MySQL)
-- ============================================================

DROP DATABASE IF EXISTS olist_bi;
CREATE DATABASE olist_bi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE olist_bi;

-- =========================
-- 1) Base Tables (9 tables)
-- =========================

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
  customer_id CHAR(32),
  customer_unique_id CHAR(32),
  customer_zip_code_prefix INT,
  customer_city VARCHAR(100),
  customer_state CHAR(2),
  INDEX idx_customers_customer_id (customer_id),
  INDEX idx_customers_unique_id (customer_unique_id),
  INDEX idx_customers_zip (customer_zip_code_prefix)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  order_id CHAR(32),
  customer_id CHAR(32),
  order_status VARCHAR(30),
  order_purchase_timestamp DATETIME,
  order_approved_at DATETIME,
  order_delivered_carrier_date DATETIME,
  order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME,
  INDEX idx_orders_order_id (order_id),
  INDEX idx_orders_customer_id (customer_id),
  INDEX idx_orders_purchase_ts (order_purchase_timestamp)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
  order_id CHAR(32),
  order_item_id INT,
  product_id CHAR(32),
  seller_id CHAR(32),
  shipping_limit_date DATETIME,
  price DECIMAL(12,2),
  freight_value DECIMAL(12,2),
  INDEX idx_items_order_id (order_id),
  INDEX idx_items_product_id (product_id),
  INDEX idx_items_seller_id (seller_id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS products;
CREATE TABLE products (
  product_id CHAR(32),
  product_category_name VARCHAR(100),
  product_name_lenght INT,
  product_description_lenght INT,
  product_photos_qty INT,
  product_weight_g INT,
  product_length_cm INT,
  product_height_cm INT,
  product_width_cm INT,
  INDEX idx_products_product_id (product_id),
  INDEX idx_products_category (product_category_name)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS category_translation;
CREATE TABLE category_translation (
  product_category_name VARCHAR(100),
  product_category_name_english VARCHAR(100),
  INDEX idx_ct_pt (product_category_name)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS sellers;
CREATE TABLE sellers (
  seller_id CHAR(32),
  seller_zip_code_prefix INT,
  seller_city VARCHAR(100),
  seller_state CHAR(2),
  INDEX idx_sellers_seller_id (seller_id),
  INDEX idx_sellers_zip (seller_zip_code_prefix)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS order_reviews;
CREATE TABLE order_reviews (
  review_id CHAR(32),
  order_id CHAR(32),
  review_score INT,
  review_comment_title VARCHAR(255),
  review_comment_message TEXT,
  review_creation_date DATETIME,
  review_answer_timestamp DATETIME,
  INDEX idx_reviews_order_id (order_id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS geolocation_raw;
CREATE TABLE geolocation_raw (
  geolocation_zip_code_prefix INT,
  geolocation_lat DECIMAL(10,6),
  geolocation_lng DECIMAL(10,6),
  geolocation_city VARCHAR(100),
  geolocation_state CHAR(2),
  INDEX idx_geo_zip (geolocation_zip_code_prefix)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS order_payments;
CREATE TABLE order_payments (
  order_id CHAR(32),
  payment_sequential INT,
  payment_type VARCHAR(30),
  payment_installments INT,
  payment_value DECIMAL(12,2),
  INDEX idx_payments_order_id (order_id)
) ENGINE=InnoDB;

