
***

## 7.3 docs/data_model.md

Create `docs/data_model.md`:

```markdown
# Data Model – Retail Operations KPI & QA Dashboard

## Overview

This project implements a classic **star schema** on top of the Instacart Market Basket dataset to support retail operations KPIs, QA checks, and an executive Power BI dashboard.

## Star Schema

- **Fact table**
  - `mart.fact_orders`
- **Dimension tables**
  - `mart.dim_date`
  - `mart.dim_product`
  - `mart.dim_customer`

## Fact Table: mart.fact_orders

- **Grain**: 1 row per (order_id, product_id)
- **Columns (core)**:
  - `order_id` – Unique order/basket identifier.
  - `product_id` – Unique product identifier.
  - `customer_id` – Derived from Instacart `user_id`.
  - `order_date_id` – Foreign key to `dim_date.date_id`.
  - `quantity` – Set to 1 per line item (one product per row).
  - `unit_price` – Simulated unit price in USD (see revenue logic).
  - `revenue` – `quantity * unit_price`.
- **Additional fields**:
  - `add_to_cart_order` – Position in the basket.
  - `reordered` – Flag if the product was ordered before by this customer.
  - `order_number`, `order_dow`, `order_hour_of_day`, `days_since_prior_order` – Behavioral attributes from raw orders.

## Dimension: mart.dim_date

- **Key**: `date_id` (integer surrogate key)
- **Columns**:
  - `date` – Calendar date.
  - `year`, `month`, `day`, `dow` – Standard date breakdown.
  - `date_iso` – `YYYY-MM-DD` string.
- **Logic**:
  - Synthetic calendar generated starting at `2015-01-01`.
  - Each order maps to a date using `order_number` as a sequential index.

## Dimension: mart.dim_product

- **Key**: `product_id`
- **Columns**:
  - `product_name`
  - `aisle_id`, `aisle`
  - `department_id`, `department`
- **Source**:
  - Joined from raw `products`, `aisles`, and `departments` tables.

## Dimension: mart.dim_customer

- **Key**: `customer_id` (from raw `user_id`)
- **Columns**:
  - `total_orders`
  - `first_order_number`
  - `last_order_number`
  - `max_days_since_prior` – max days between subsequent orders (proxy for recency).

## Relationships

Text-based diagram:

```text
dim_date (date_id)      dim_product (product_id)      dim_customer (customer_id)
        \                        |                           /
         \                       |                          /
                      fact_orders
(order_date_id, product_id, customer_id, quantity, unit_price, revenue, ...)
