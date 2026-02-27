# KPI Dictionary -- Retail Operations KPI & QA Dashboard (Instacart)

------------------------------------------------------------------------

## Data Context

-   Dataset: Instacart Market Basket Analysis (Kaggle).
-   Fact grain: 1 row per (order_id, product_id).
-   Customer: customer_id mapped from Instacart user_id.
-   Date: Synthetic calendar created by mapping order_number to
    dim_date.
-   Quantity: Each line item treated as quantity = 1.
-   Revenue model:
    -   Department-level base price assigned.
    -   unit_price_usd = department_base_price \* (1 + (product_id % 5)
        \* 0.05)
    -   revenue = quantity \* unit_price_usd
    -   Revenue is simulated for analytical comparison only.

------------------------------------------------------------------------

# Core KPIs

## KPI 01 -- Total Revenue

Definition: Sum of simulated revenue across all order line items.

``` sql
SELECT SUM(revenue) AS total_revenue
FROM mart.fact_orders;
```

Business Use: Tracks overall platform performance.

------------------------------------------------------------------------

## KPI 02 -- Total Orders

Definition: Count of distinct order_id.

``` sql
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM mart.fact_orders;
```

Business Use: Measures transaction volume.

------------------------------------------------------------------------

## KPI 03 -- Average Order Value (AOV)

Definition: Total Revenue divided by Total Orders.

``` sql
SELECT
    SUM(revenue) / NULLIF(COUNT(DISTINCT order_id), 0) AS avg_order_value
FROM mart.fact_orders;
```

Business Use: Evaluates basket monetization efficiency.

------------------------------------------------------------------------

## KPI 04 -- Basket Size

Definition: Average number of distinct products per order.

``` sql
SELECT AVG(items_per_order) AS avg_basket_size
FROM (
    SELECT
        order_id,
        COUNT(DISTINCT product_id) AS items_per_order
    FROM mart.fact_orders
    GROUP BY order_id
) t;
```

Business Use: Measures cross-sell depth and purchasing behavior.

------------------------------------------------------------------------

## KPI 05 -- Weekly Active Customers

Definition: Distinct customers placing at least one order in a given
week.

``` sql
SELECT
    w.week_start,
    COUNT(DISTINCT f.customer_id) AS weekly_active_customers
FROM mart.fact_orders f
JOIN mart.v_date_week w
  ON f.order_date_id = w.date_id
GROUP BY w.week_start
ORDER BY w.week_start;
```

Business Use: Tracks customer engagement trends.

------------------------------------------------------------------------

## KPI 06 -- Repeat Purchase Rate

Definition: Percentage of customers with two or more distinct orders.

``` sql
WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS orders_cnt
    FROM mart.fact_orders
    GROUP BY customer_id
)
SELECT
    COUNT(*) FILTER (WHERE orders_cnt >= 2)::NUMERIC
    / NULLIF(COUNT(*), 0) AS repeat_purchase_rate
FROM customer_order_counts;
```

Business Use: Measures retention strength.

------------------------------------------------------------------------

## KPI 07 -- Revenue by Department

Definition: Revenue aggregated by product department.

``` sql
SELECT
    dp.department,
    SUM(f.revenue) AS revenue
FROM mart.fact_orders f
JOIN mart.dim_product dp
  ON f.product_id = dp.product_id
GROUP BY dp.department
ORDER BY revenue DESC;
```

Business Use: Identifies high-performing categories.

------------------------------------------------------------------------

## KPI 08 -- Top Products

Definition: Top 20 products ranked by revenue.

``` sql
SELECT
    dp.product_name,
    SUM(f.revenue) AS revenue,
    COUNT(DISTINCT f.order_id) AS orders_cnt
FROM mart.fact_orders f
JOIN mart.dim_product dp
  ON f.product_id = dp.product_id
GROUP BY dp.product_name
ORDER BY revenue DESC
LIMIT 20;
```

Business Use: Supports SKU-level merchandising decisions.

------------------------------------------------------------------------

## KPI 09 -- Revenue Month-over-Month Growth

Definition: Percentage change in monthly revenue compared to previous
month.

``` sql
WITH monthly_revenue AS (
    SELECT
        m.month_start,
        SUM(f.revenue) AS revenue
    FROM mart.fact_orders f
    JOIN mart.v_date_month m
      ON f.order_date_id = m.date_id
    GROUP BY m.month_start
)
SELECT
    month_start,
    revenue,
    (revenue - LAG(revenue) OVER (ORDER BY month_start))
    / NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0)
    AS revenue_mom_growth
FROM monthly_revenue
ORDER BY month_start;
```

Business Use: Identifies acceleration or slowdown in revenue trends.

------------------------------------------------------------------------

## KPI 10 -- Cohort Retention

Definition: Percentage of customers from a cohort month returning in
subsequent months.

Business Logic: 1. Identify first purchase month per customer. 2. Track
subsequent monthly activity. 3. Compute retention rate = active
customers / cohort size.

Business Use: Evaluates lifecycle performance and long-term retention.
