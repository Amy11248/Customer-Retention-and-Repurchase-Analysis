# 🧱 Data Modeling Logic

This project uses SQL to preprocess customer transaction data and build an analytical dataset for customer lifecycle, value segmentation, and behavioral analysis. Below is a complete overview of the modeling steps.

---

## 1. 🧾 Source Data Overview

- **Dataset**: [UCI Online Retail Dataset (01/12/2010–09/12/2011)](https://archive.ics.uci.edu/dataset/352/online+retail)
- **Source Table**: Single raw table with the following fields:
  - `InvoiceNo`, `StockCode`, `Description`, `Quantity`, `InvoiceDate`, `UnitPrice`, `CustomerID`, `Country`
- **Initial Format**: CSV imported into Power BI and then modeled using SQL in BigQuery

---

## 2. 🧹 Data Cleaning and Preparation

### Cleaning Steps (in SQL):

- **Removed anonymous customers**: `CustomerID IS NULL`
- **Removed invalid transactions**:
  - Entirely negative quantity & negative revenue → labeled as "Return"
  - Revenue = 0 → labeled as "Inventory adjustment"
- **Filtered to valid sales only**:
  - Kept only rows labeled as "Normal sales"

### Saved as:

- `Customer_behaviour_analysis` (cleaned fact table for further modeling)

---

## 3. 📆 Monthly Customer Behavior Summary

Saved as: `customer_retention_monthly_summary`

### Fields included:

- `customer_id`, `current_month`, `first_order_month`, `first_order_date`
- `tenure_months` = months between first order and current month
- `country`
- `is_retained` = 1 if also ordered in previous month
- `is_new_customer` = 1 if first order in current\_month
- `customer_lifecycle_stage` (based on tenure)
- `monthly_revenue`, `prev_monthly_revenue`, `avg_order_value`, `order_count`

### SQL Highlights:

- Used `TIMESTAMP_DIFF` and `LAG()` to identify retention
- Joined first-order data using `MIN(InvoiceDate)`
- Calculated retention as:
  ```sql
  Retention Rate = Customers with prev_monthly_revenue > 0 / Total customers last month
  ```

---

## 4. 🧷 Lifecycle & Value Segmentation

Saved as: `customer_lifecycle_summary`

### Lifecycle Stage:

| Stage  | Rule           |
| ------ | -------------- |
| New    | tenure = 0     |
| Early  | 1 ≤ tenure ≤ 4 |
| Active | 5 ≤ tenure ≤ 8 |
| Loyal  | tenure > 8     |

### Value Segmentation:

- Revenue-based:
  - `High Value`: total revenue ≥ 1800
  - `Medium Value`: 300–1799.99
  - `Low Value`: < 300
- AOV-based:
  - `High AOV`: avg AOV ≥ 450
  - `Medium AOV`: 180–449.99
  - `Low AOV`: < 180

### Combined Grouping:

- `customer_group_label` = `Revenue Tier - AOV Tier`

### SQL Highlights:

- `ROW_NUMBER()` used to get final lifecycle stage
- Aggregated tenure, revenue, AOV across months

---

## 5. ⭐ Power BI Data Model Structure

We designed a **star schema**:

### Fact Tables:

- `customer_retention_monthly_summary` (monthly behavior)
- `customer_lifecycle_summary` (lifecycle stats)

### Dimension Tables:

- `dim_customer` (CustomerID, Country)
- `dim_country`
- `dim_calendar`
- (Optional) `dim_product`

### Relationships:

- CustomerID for customer-based joins
- `current_month` linked to `dim_calendar[Date]`
- Country used for aggregation and filtering

---

## 6. 🧠 Power BI Measures & Bookmark Design

### DAX Measures Used:

- `Average Order Count = DIVIDE([Total Order Count],[Total Customer Count])`
- `Average Order Value = DIVIDE([Total Revenue],[Total Order Count])`
- `Total Customer Count = DISTINCTCOUNT(customer_retention_monthly_summary[customer_id])`
- `Total Order Count = SUM(customer_retention_monthly_summary[order_count])`
- `Total Revenue = SUM(customer_retention_monthly_summary[monthly_revenue])`
- `New Customer Count = CALCULATE(DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]), FILTER('customer_retention_monthly_summary',[is_new_customer]=1))`
- `Retained Customer Count = CALCULATE(DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]), FILTER('customer_retention_monthly_summary',[is_retained]=1))`
- `Previous Month Customer Count = VAR PrevMonth = CALCULATE([Total Customer Count], DATEADD(dim_month[Month], -1, MONTH)) RETURN IF(ISBLANK(PrevMonth), BLANK(), PrevMonth)`
- `Churn Customer Count = VAR prev_month_customer = CALCULATE(DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]), DATEADD('dim_month'[Month],-1,MONTH)) VAR retained_customer = CALCULATE(DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]), FILTER('customer_retention_monthly_summary',[is_retained]=1)) VAR churn_customer = prev_month_customer - retained_customer RETURN IF(ISBLANK(prev_month_customer), BLANK(), churn_customer)`
- `Churn Rate = DIVIDE([Churn Customer Count], [Previous Month Customer Count])`
- `Retention Rate = DIVIDE(CALCULATE(DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]), customer_retention_monthly_summary[is_retained] = 1), CALCULATE(DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]), DATEADD(dim_month[Month], -1, MONTH)))`
- `Consecutive Purchase Rate by Final Stage = DIVIDE(CALCULATE(DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]), customer_retention_monthly_summary[is_retained] = 1), CALCULATE(DISTINCTCOUNT(customer_retention_monthly_summary[customer_id])))`

### Bookmarks Implemented:

- `Default_Main_view`: for Customer Overview Page, with insight hidden
- `Insight_show`: to show insight panel
- `Hide_Newcustomer_insight`: on Lifecycle Analysis page, to hide pop-up
- `Show_new_customer_insight`: to show insight
- `Default_lifecycle_view`: to clear filters on lifecycle page
- `Default_value_view`: to clear filters on value page

---

## 7. 🎯 Final Output & Dashboard Design

Dashboard contains **4 pages**:

1. **Customer Overview** – KPIs, total customers, retention trend
2. **Map View** – Revenue & AOV by country
3. **Lifecycle & Behavior Analysis** – Stage-based segmentation and behavior
4. **Value & Repurchase Analysis** – Customer tiers, retention, repeat rate

### Advanced Features:

- Bookmarks for modal pop-ups and view switching
- Conditional formatting for value tiers
- Tooltips and slicers for dynamic analysis

---

## ✅ Final Result

The entire modeling pipeline enabled full-funnel analysis from customer acquisition to retention and value contribution. It supports deep lifecycle analytics and value-based targeting strategies, forming a complete analytical story ready for business use or portfolio showcase.

---

## 📌 Project Summary

### 🔧 Key Skills Gained:

1. Using BigQuery’s SQL editor to visually debug logic before import
2. Recognizing the importance of granularity when building SQL models
3. Leveraging Bookmarks, Selection Pane, and Buttons in Power BI for interactivity
4. Applying `.json` theme files for consistent visual styling across all visuals
5. Building retention and value segmentation models based on behavioral metrics

### 🚧 Key Challenges Faced:

1. Ensuring data cleaning logic was robust and validated through SQL + DAX cross-check
2. Adapting SQL modeling to ensure Power BI interactivity (e.g., do not calculate retention in SQL if it limits visualization flexibility)
3. Understanding fact vs. dimension separation for multiple behavioral tables
4. Judging which missing data can be excluded based on stakeholder intent
5. Clearly identifying analysis **scope** from stakeholder perspective to avoid over-modeling

