/* ============================================================
   RETAIL OPS — QA SUITE
   Purpose: Validate star schema integrity and KPI reliability
   ============================================================ */


/* ============================================================
   QA 01: Grain validation — fact_orders
   Pass criteria: returns 0 rows
   ============================================================ */

SELECT
    order_id,
    product_id,
    COUNT(*) AS row_count
FROM mart.fact_orders
GROUP BY order_id, product_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC;



/* ============================================================
   QA 02: Null rates on key columns
   Pass criteria: null_pct = 0 for all keys
   ============================================================ */

SELECT
    'order_id' AS column_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_count,
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_id IS NULL) / COUNT(*), 2) AS null_pct
FROM mart.fact_orders

UNION ALL

SELECT
    'product_id',
    COUNT(*) FILTER (WHERE product_id IS NULL),
    COUNT(*),
    ROUND(100.0 * COUNT(*) FILTER (WHERE product_id IS NULL) / COUNT(*), 2)
FROM mart.fact_orders

UNION ALL

SELECT
    'customer_id',
    COUNT(*) FILTER (WHERE customer_id IS NULL),
    COUNT(*),
    ROUND(100.0 * COUNT(*) FILTER (WHERE customer_id IS NULL) / COUNT(*), 2)
FROM mart.fact_orders

UNION ALL

SELECT
    'order_date_id',
    COUNT(*) FILTER (WHERE order_date_id IS NULL),
    COUNT(*),
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_date_id IS NULL) / COUNT(*), 2)
FROM mart.fact_orders;



/* ============================================================
   QA 03: Orphaned dimension joins
   Pass criteria: each query returns 0 rows
   ============================================================ */

-- Product orphans
SELECT
    f.product_id,
    COUNT(*) AS fact_rows
FROM mart.fact_orders f
LEFT JOIN mart.dim_product dp
    ON f.product_id = dp.product_id
WHERE dp.product_id IS NULL
GROUP BY f.product_id
ORDER BY fact_rows DESC;


-- Customer orphans
SELECT
    f.customer_id,
    COUNT(*) AS fact_rows
FROM mart.fact_orders f
LEFT JOIN mart.dim_customer dc
    ON f.customer_id = dc.customer_id
WHERE dc.customer_id IS NULL
GROUP BY f.customer_id
ORDER BY fact_rows DESC;


-- Date orphans
SELECT
    f.order_date_id,
    COUNT(*) AS fact_rows
FROM mart.fact_orders f
LEFT JOIN mart.dim_date dd
    ON f.order_date_id = dd.date_id
WHERE dd.date_id IS NULL
GROUP BY f.order_date_id
ORDER BY fact_rows DESC;



/* ============================================================
   QA 04: Revenue reconciliation
   Pass criteria: inconsistent_rows = 0
   ============================================================ */

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE revenue <> quantity * unit_price
           OR revenue IS NULL
           OR unit_price IS NULL
    ) AS inconsistent_rows
FROM mart.fact_orders;


-- Suspicious price or revenue rows
SELECT *
FROM mart.fact_orders
WHERE unit_price <= 0
   OR revenue <= 0
   OR unit_price IS NULL
   OR revenue IS NULL
LIMIT 100;



/* ============================================================
   QA 05: Basket size outliers
   Purpose: detect duplication or ETL issues
   ============================================================ */

WITH order_sizes AS (
    SELECT
        order_id,
        COUNT(DISTINCT product_id) AS items_per_order
    FROM mart.fact_orders
    GROUP BY order_id
)
SELECT
    MIN(items_per_order) AS min_items,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY items_per_order) AS p50_items,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY items_per_order) AS p90_items,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY items_per_order) AS p99_items,
    MAX(items_per_order) AS max_items
FROM order_sizes;


-- Extremely large baskets
WITH order_sizes AS (
    SELECT
        order_id,
        COUNT(DISTINCT product_id) AS items_per_order
    FROM mart.fact_orders
    GROUP BY order_id
)
SELECT
    order_id,
    items_per_order
FROM order_sizes
WHERE items_per_order > 100
ORDER BY items_per_order DESC
LIMIT 100;



/* ============================================================
   QA 06: Quantity sanity
   Pass criteria: quantity always 1
   ============================================================ */

SELECT
    MIN(quantity) AS min_q,
    MAX(quantity) AS max_q,
    AVG(quantity) AS avg_q
FROM mart.fact_orders;



/* ============================================================
   QA 07: Date mapping sanity
   Pass criteria:
   - missing_date_id = 0
   - reasonable date range
   ============================================================ */

SELECT
    COUNT(*) AS fact_rows,
    COUNT(*) FILTER (WHERE order_date_id IS NULL) AS missing_date_id
FROM mart.fact_orders;


SELECT
    MIN(dd.date) AS first_order_date,
    MAX(dd.date) AS last_order_date
FROM mart.fact_orders f
JOIN mart.dim_date dd
    ON f.order_date_id = dd.date_id;


