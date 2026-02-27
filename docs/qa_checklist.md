# QA Checklist – Retail Operations KPI & QA Dashboard

All QA queries are located in sql/04_qa_checks.sql.

---

## QA 01 – Grain Check

Ensure 1 row per (order_id, product_id).

Pass criteria:
0 rows returned.

---

## QA 02 – Null Key Check

Ensure 0% null in:
- order_id
- product_id
- customer_id
- order_date_id

Pass criteria:
All null_pct = 0.

---

## QA 03 – Orphan Dimension Check

No fact rows without matching:
- product
- customer
- date

Pass criteria:
0 rows returned.

---

## QA 04 – Revenue Reconciliation

Validate:
revenue = quantity * unit_price

Pass criteria:
inconsistent_rows = 0.

---

## QA 05 – Basket Size Outliers

Validate realistic distribution.
Check p50, p90, p99, max.

---

## QA 06 – Date Mapping

Ensure:
- No null date_id
- Date range within synthetic calendar.