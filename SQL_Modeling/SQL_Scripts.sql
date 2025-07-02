
-- ======================================
-- 📁 SQL_Modeling/SQL_Scripts.sql
-- Project: Customer Retention Analysis
-- Author: Huimin Zhou 
-- Date: 2025.07.01
-- ======================================


-- ========================
-- 1. Monthly Customer Retention Modeling
-- ========================

-- customer table with basic information
WITH customer AS (
  SELECT  
CustomerID AS customer_id,
DATE(DATE_TRUNC(InvoiceDate,MONTH)) AS current_month,
Country AS country,
COUNT(DISTINCT InvoiceNo) AS order_count,
ROUND(SUM(Quantity*UnitPrice),2) AS monthly_revenue,
ROUND(IFNULL(SUM(Quantity*UnitPrice)/COUNT(DISTINCT InvoiceNo),0),2) AS avg_order_value
FROM `hip-return-451013-j2.Online_retail_analysis.Customer_behaviour_analysis`
WHERE Customer_Status='Has Customer ID'
GROUP BY CustomerID,DATE(DATE_TRUNC(InvoiceDate,MONTH)),Country
),
-- customer table with previous month revenue
customer_prev AS(
  SELECT
  c1.customer_id,
  c1.current_month,
  c1.country,
  c1.monthly_revenue,
  c2.monthly_revenue AS prev_monthly_revenue,
  c1.avg_order_value,
  c1.order_count
  FROM customer AS c1
  LEFT JOIN customer AS c2 on c1.customer_id = c2.customer_id AND TIMESTAMP_DIFF(c1.current_month, c2.current_month, MONTH)=1 AND c1.country=c2.country
),
-- find out the first porder date and month of each Customer ID
first_order AS(
  SELECT
  CustomerID,
  MIN(InvoiceDate) AS first_order_date,
  DATE(DATE_TRUNC(MIN(InvoiceDate),MONTH)) AS first_order_month
  FROM `hip-return-451013-j2.Online_retail_analysis.Customer_behaviour_analysis`
  GROUP BY CustomerID
),
-- join the customer_prev with first order date and first_order_month
customer_table_with_first_purchase AS(
  SELECT
  customer_id,
  current_month,
  first_order_month,
  first_order_date,
  country,
  monthly_revenue,
  prev_monthly_revenue,
  avg_order_value,
  order_count
  FROM customer_prev
  LEFT JOIN first_order ON CustomerID=customer_id
)
-- retained customer has prev_monthly_revenue; new customer has the first_order_month in the same month of current_month
SELECT 
customer_id,
current_month,
first_order_month,
first_order_date,
TIMESTAMP_DIFF(current_month, first_order_month,MONTH) AS tenure_months,
country,
CASE 
WHEN prev_monthly_revenue IS NULL THEN 0
ELSE 1 END AS is_retained,
CASE 
WHEN first_order_month=current_month THEN 1
ELSE 0 END is_new_customer,
THEN 'New'
  WHEN TIMESTAMP_DIFF(current_month, first_order_month,MONTH) BETWEEN 1 AND 4 THEN 'Early'
  WHEN TIMESTAMP_DIFF(current_month, first_order_month,MONTH) BETWEEN 5 AND 8 THEN 'Active'
  ELSE 'Loyal'
END AS customer_lifecycle_stage,
monthly_revenue,
prev_monthly_revenue,
avg_order_value,
order_count
FROM customer_table_with_first_purchase

-- ========================
-- 2. Lifecycle & Value Segmentation Modeling
-- ========================
WITH base AS (
  SELECT 
    customer_id,
    current_month,
    customer_lifecycle_stage
  FROM `hip-return-451013-j2.online_retail_analysis_pro.customer_retention_monthly_summary`
),
final_stage_lookup AS (
  SELECT 
    customer_id,
    customer_lifecycle_stage AS final_stage
  FROM (
    SELECT 
      customer_id,
      current_month,
      customer_lifecycle_stage,
      ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY current_month DESC) AS rn
    FROM base
  )
  WHERE rn = 1
)
SELECT 
  s.customer_id,
  MAX(tenure_months) AS max_tenure,
  f.final_stage,
  CASE
  WHEN MAX(tenure_months) <= 3 THEN 'Short-Term'
  WHEN MAX(tenure_months) BETWEEN 4 AND 8 THEN 'Mid-Term'
  ELSE 'Long-Term'
END AS lifecycle_duration_group,
  COUNT(DISTINCT current_month) AS active_months,
  ROUND(AVG(avg_order_value),2) AS avg_order_value,
  SUM(order_count) AS total_order_count,
  ROUND(SUM(monthly_revenue),2) AS total_revenue,
  CASE 
  WHEN ROUND(SUM(monthly_revenue),2)  >= 1800 THEN 'High Value'
  WHEN ROUND(SUM(monthly_revenue),2) BETWEEN 300 AND 1799.99 THEN 'Medium Value'
  ELSE 'Low Value'
END AS revenue_segment,
CASE 
  WHEN ROUND(AVG(avg_order_value),2) >= 450 THEN 'High AOV'
  WHEN ROUND(AVG(avg_order_value),2) BETWEEN 180 AND 499.99 THEN 'Medium AOV'
  ELSE 'Low AOV'
END AS avg_order_value_segment,
CONCAT(
  CASE 
    WHEN ROUND(SUM(monthly_revenue),2)  >= 1800 THEN 'High Value'
    WHEN ROUND(SUM(monthly_revenue),2) BETWEEN 300 AND 1799.99 THEN 'Medium Value'
    ELSE 'Low Value'
  END,
  ' - ',
  CASE 
    WHEN ROUND(AVG(avg_order_value),2) >= 450 THEN 'High AOV'
    WHEN ROUND(AVG(avg_order_value),2) BETWEEN 180 AND 499.99 THEN 'Medium AOV'
    ELSE 'Low AOV'
  END
) AS customer_group_label
 FROM `hip-return-451013-j2.online_retail_analysis_pro.customer_retention_monthly_summary` AS s
LEFT JOIN final_stage_lookup AS f
  ON s.customer_id = f.customer_id
GROUP BY s.customer_id, f.final_stage
