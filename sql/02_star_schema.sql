-- ==========================================
-- 02_star_schema.sql
-- Star Schema Build
-- ==========================================

CREATE SCHEMA IF NOT EXISTS mart;

-- dim_date
CREATE TABLE mart.dim_date AS
WITH RECURSIVE dates AS (...)
SELECT ...;

ALTER TABLE mart.dim_date
ADD CONSTRAINT pk_dim_date PRIMARY KEY (date_id);

-- dim_product
CREATE TABLE mart.dim_product AS
SELECT ...
FROM raw.products p
JOIN raw.aisles a
  ON p.aisle_id = a.aisle_id
JOIN raw.departments d
  ON p.department_id = d.department_id;

-- fact_orders
CREATE TABLE mart.fact_orders AS
SELECT ...
FROM stg.stg_order_lines ...