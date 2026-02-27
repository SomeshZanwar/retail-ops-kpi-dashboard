/* ============================================================
   RETAIL OPS KPI PACK
   Schema: mart
   Grain: 1 row per (order_id, product_id)
   ============================================================ */

/* ============================================================
   Helper View: Month Buckets
   ============================================================ */

CREATE OR REPLACE VIEW mart.v_date_month AS
SELECT
    d.date_id,
    d.date,
    date_trunc('month', d.date)::date AS month_start,
    to_char(d.date, 'YYYY-MM') AS month_yyyy_mm
FROM mart.dim_date d;


/* ============================================================
   Helper View: ISO Week Buckets
   ============================================================ */

CREATE OR REPLACE VIEW mart.v_date_week AS
SELECT
    d.date_id,
    d.date,
    date_trunc('week', d.date)::date AS week_start,
    to_char(d.date, 'IYYY-IW') AS iso_year_week
FROM mart.dim_date d;

/* ============================================================
   KPI 01: Total Revenue
   Definition: Sum of simulated revenue across all order lines
   ============================================================ */

SELECT SUM(revenue) AS total_revenue
FROM mart.fact_orders;

/* ============================================================
   KPI 02: Total Orders
   Definition: Distinct order_id count
   ============================================================ */

SELECT COUNT(DISTINCT order_id) AS total_orders
FROM mart.fact_orders;

/* ============================================================
   KPI 03: Average Order Value
   Definition: Revenue / Orders
   ============================================================ */

SELECT
    SUM(revenue) / NULLIF(COUNT(DISTINCT order_id), 0) AS avg_order_value
FROM mart.fact_orders;

/* ============================================================
   KPI 04: Average Basket Size
   Definition: Avg distinct products per order
   ============================================================ */

SELECT
    AVG(items_per_order)::NUMERIC(10,2) AS avg_basket_size
FROM (
    SELECT
        order_id,
        COUNT(DISTINCT product_id) AS items_per_order
    FROM mart.fact_orders
    GROUP BY order_id
) t;

/* ============================================================
   KPI 05: Weekly Active Customers
   Definition: Customers with ≥1 order in a week
   ============================================================ */

SELECT
    w.week_start,
    COUNT(DISTINCT f.customer_id) AS weekly_active_customers
FROM mart.fact_orders f
JOIN mart.v_date_week w
    ON f.order_date_id = w.date_id
GROUP BY w.week_start
ORDER BY w.week_start;


/* ============================================================
   KPI 06: Repeat Purchase Rate
   Definition: Customers with ≥2 orders / customers with ≥1
   ============================================================ */

WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS orders_cnt
    FROM mart.fact_orders
    GROUP BY customer_id
)
SELECT
    COUNT(CASE WHEN orders_cnt >= 2 THEN 1 END)::NUMERIC
    / NULLIF(COUNT(*), 0) AS repeat_purchase_rate
FROM customer_order_counts;

/* ============================================================
   KPI 07: Revenue by Department
   ============================================================ */

SELECT
    dp.department,
    SUM(f.revenue) AS revenue
FROM mart.fact_orders f
JOIN mart.dim_product dp
    ON f.product_id = dp.product_id
GROUP BY dp.department
ORDER BY revenue DESC;

/* ============================================================
   KPI 08: Top 20 Products by Revenue
   ============================================================ */

SELECT
    f.product_id,
    dp.product_name,
    SUM(f.revenue) AS revenue,
    COUNT(DISTINCT f.order_id) AS orders_cnt
FROM mart.fact_orders f
JOIN mart.dim_product dp
    ON f.product_id = dp.product_id
GROUP BY f.product_id, dp.product_name
ORDER BY revenue DESC
LIMIT 20;

/* ============================================================
   KPI 09: Monthly Revenue and MoM Growth
   ============================================================ */

WITH monthly AS (
    SELECT
        m.month_start,
        SUM(f.revenue) AS revenue,
        COUNT(DISTINCT f.order_id) AS orders
    FROM mart.fact_orders f
    JOIN mart.v_date_month m
        ON f.order_date_id = m.date_id
    GROUP BY m.month_start
)
SELECT
    month_start,
    revenue,
    orders,
    revenue - LAG(revenue) OVER (ORDER BY month_start) AS revenue_change,
    (revenue - LAG(revenue) OVER (ORDER BY month_start))
        / NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0)
        AS revenue_mom_growth
FROM monthly
ORDER BY month_start;


/* ============================================================
   KPI 10: Monthly Cohort Retention
   ============================================================ */

WITH first_order AS (
    SELECT
        f.customer_id,
        MIN(m.month_start) AS cohort_month
    FROM mart.fact_orders f
    JOIN mart.v_date_month m
        ON f.order_date_id = m.date_id
    GROUP BY f.customer_id
),
customer_month_activity AS (
    SELECT DISTINCT
        f.customer_id,
        m.month_start AS activity_month
    FROM mart.fact_orders f
    JOIN mart.v_date_month m
        ON f.order_date_id = m.date_id
),
cohort_activity AS (
    SELECT
        fo.cohort_month,
        cma.activity_month,
        DATE_PART('month', age(cma.activity_month, fo.cohort_month))::INT
            AS months_since_cohort,
        COUNT(DISTINCT cma.customer_id) AS active_customers
    FROM first_order fo
    JOIN customer_month_activity cma
        ON fo.customer_id = cma.customer_id
    GROUP BY fo.cohort_month, cma.activity_month,
             DATE_PART('month', age(cma.activity_month, fo.cohort_month))
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM first_order
    GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    ca.months_since_cohort,
    ca.active_customers,
    cs.cohort_size,
    ca.active_customers::NUMERIC / NULLIF(cs.cohort_size, 0)
        AS retention_rate
FROM cohort_activity ca
JOIN cohort_sizes cs
    ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month, ca.months_since_cohort;


/* ============================================================
   KPI 11: Orders per Active Customer (Weekly)
   ============================================================ */

WITH weekly_stats AS (
    SELECT
        w.week_start,
        COUNT(DISTINCT f.customer_id) AS active_customers,
        COUNT(DISTINCT f.order_id) AS orders
    FROM mart.fact_orders f
    JOIN mart.v_date_week w
        ON f.order_date_id = w.date_id
    GROUP BY w.week_start
)
SELECT
    week_start,
    active_customers,
    orders,
    orders::NUMERIC / NULLIF(active_customers, 0)
        AS orders_per_active_customer
FROM weekly_stats
ORDER BY week_start;

