# Customer Loyalty Analytics 
## Project Overview
This project implements an end-to-end **Customer Loyalty Analytics MVP** as part of a hackathon challenge.  
The solution covers **data ingestion, data quality checks, core business logic (loyalty points), customer segmentation (RFM), and visualization using Power BI**.

The objective is to demonstrate how raw transactional data can be transformed into meaningful customer insights and loyalty metrics.

---

## Scope of the MVP

### 1. Data Ingestion
- Generated sample datasets for:
  - Customers
  - Products
  - Stores
  - Sales
  - Sale Items
- Loaded CSV files into Power BI using **Power Query**
- Treated imported data as **landing (raw) tables**

**Tools Used**
- Power BI Desktop  
- Power Query Editor  

---

### 2. Data Quality & Data Handling
Applied basic data quality rules using **Power Query**:
- Null value checks
- Duplicate record checks
- Invalid reference checks (e.g., product_id not found in products table)

Based on validation:
- Clean data stored in **clean tables**
- Invalid data conceptually mapped to **reject/error tables**

**Outcome**
- Reliable, analysis-ready datasets
- Proper data types assigned (date, numeric, text)

---

### 3. Data Model (Star Schema)
Created relationships in Power BI Model View:
- `customers (1) → sales (*)`
- `stores (1) → sales (*)`
- `products (1) → sale_items (*)`
- `sales (1) → sale_items (*)`

This ensures correct filter flow and aggregation behavior.

---

### 4. Core Business Logic – Loyalty Points
Implemented loyalty logic based on the `loyalty_rules` table.

**Rules**
| Rule Name | Min Spend | Bonus Points |
|---------|----------|--------------|
| Base | 0 | 0 |
| Mid Spend Bonus | 500 | 100 |
| High Spend Bonus | 1000 | 300 |

**Implementation**
- Created calculated columns/measures in Power BI using **DAX**
- Loyalty points calculated per transaction based on total spend
- Updated:
  - Customer total loyalty points
  - Last purchase date

---

### 5. Customer Segmentation (RFM)
Computed **RFM metrics**:
- **Recency** – Days since last purchase
- **Frequency** – Number of purchases
- **Monetary** – Total spend

Identified customer segments:
- **High Spenders** – Top 10% by monetary value
- **At Risk** – No purchase in last 30 days but have loyalty points

Updated `segment_id` in customer details.

---

### 6. Output & Visualization
Created Power BI dashboards showing:
- Customer Segments Overview
- Loyalty Points Summary
- Basic RFM Metrics

These dashboards allow business users to:
- Identify high-value customers
- Track loyalty performance
- Detect at-risk customers

---

## Documentation & Version Control
- ER Diagram created from Power BI Model View
- Screenshots and diagrams exported
- All artifacts uploaded to GitHub

