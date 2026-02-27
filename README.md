# Retail Operations KPI & QA Dashboard (Instacart)

End-to-end BI and Analytics Engineering project.

---

## Overview

Built a dimensional model and executive dashboard from Instacart Market Basket data.

Pipeline:
Raw CSV → PostgreSQL staging → Star schema → KPI SQL → QA suite → Power BI dashboard.

---

## Tech Stack

- PostgreSQL
- SQL
- Power BI Desktop
- Git / GitHub

---

## Architecture

fact_orders (grain: order_id, product_id)  
dim_date  
dim_product  
dim_customer  

---

## Key KPIs

- Total Revenue
- Total Orders
- Average Order Value
- Basket Size
- Weekly Active Customers
- Repeat Purchase Rate
- Revenue by Department
- Top Products
- MoM Growth
- Cohort Retention

---

## QA Layer

- Grain enforcement
- Null checks
- Orphan detection
- Revenue reconciliation
- Outlier detection

---

## Dashboard

Executive overview includes:
- KPI cards
- Revenue & Orders trend
- Revenue by Department
- Top Products
- Customer Activity trend

Screenshot located in:
dashboard/screenshots/dashboard_overview.png

---

## Limitations

- Prices simulated.
- Dates synthetic.
- Revenue directional only.

---

## Status

Complete and production-ready.