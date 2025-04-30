# Alt-Mobility-Customer-Analysis

# Customer Orders & Payments Analysis – SQL Queries

## 📊 Overview

This repository contains SQL queries used for analyzing **customer orders and payments data** as part of a comprehensive BI reporting project using **Power BI**.

The dataset includes two primary tables:
- `customer_orders`: Contains order-level information including dates, amounts, status, and customer identifiers.
- `payments`: Contains payment transaction details for each order, including method and payment status.

## 🧠 Approach

The goal was to extract **insightful metrics and trends** related to:
- Order volumes and revenue
- Payment completion and methods
- Customer retention and behavior across time

Key steps involved:

1. **Data Cleaning & Validation**
   - Ensured correct data types and removed any invalid or null values.
   - Checked referential integrity between `customer_orders` and `payments` using `order_id`.

2. **Core Metrics Computation**
   - Total Orders
   - Total Revenue
   - Payments Received
   - Average Order Value (AOV)
   - Retention KPIs: Best Retention, Repeating Customers, etc.

3. **Cohort Analysis for Retention**
   - Identified customer’s **first order month**.
   - Tracked repeat purchases in subsequent months.
   - Used DAX in Power BI to visualize cohort retention.

4. **Performance Breakdown**
   - Used `ORDER BY` and `GROUP BY` to analyze trends over time, such as:
     - Monthly order and payment growth
     - Order status breakdowns
     - Payment method preferences

5. **Business KPIs**
   - Highlighted key indicators like:
     - Best-performing customer cohort
     - Total Repeating Customers
     - Monthly retentions

## 📁 File Structure

- `/queries/`: Contains individual `.sql` files for key queries (KPIs, retention, trends).
- `README.md`: This file.

## 🛠️ Tools Used

- SQL (MySQL-compatible syntax)
- Power BI (DAX for visual-level measures)
- Excel (for early exploration)

---

## 📌 Notes

This SQL layer served as the foundation for creating interactive dashboards in Power BI. DAX was later used for dynamic metrics and visual-level calculations that couldn't be directly handled in SQL.

