-- ==========================================
-- 01_staging.sql
-- Raw + Staging Layer
-- ==========================================

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS stg;

-- Raw tables
CREATE TABLE raw.orders (...);
CREATE TABLE raw.order_products_prior (...);
CREATE TABLE raw.products (...);
CREATE TABLE raw.aisles (...);
CREATE TABLE raw.departments (...);

-- Staging table
CREATE TABLE stg.stg_order_lines AS
SELECT ...
FROM raw.orders o
JOIN raw.order_products_prior p
  ON o.order_id = p.order_id;