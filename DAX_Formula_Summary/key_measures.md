## 📌 Total Revenue

**Location**: Customer Overview\
**Type**: KPI

**Explanation**:\
Calculate total monthly revenue across all customers.

**DAX Formula**:

```DAX
Total Revenue =
SUM(customer_retention_monthly_summary[monthly_revenue])
```

---

## 📌 Total Customer Count

**Location**: Customer Overview\
**Type**: KPI

**Explanation**:\
Count the number of distinct customers for the selected month.

**DAX Formula**:

```DAX
Total Customer Count =
DISTINCTCOUNT(customer_retention_monthly_summary[customer_id])
```

---

## 📌 Total Order Count

**Location**: Customer Overview\
**Type**: KPI

**Explanation**:\
Sum of total orders placed by all customers.

**DAX Formula**:

```DAX
Total Order Count =
SUM(customer_retention_monthly_summary[order_count])
```

---

## 📌 Retained Customer Count

**Location**: Customer Overview\
**Type**: Supporting Measure

**Explanation**:\
Count of customers who also purchased in the previous month.

**DAX Formula**:

```DAX
Retained Customer Count =
CALCULATE(
    DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]),
    FILTER('customer_retention_monthly_summary', [is_retained] = 1)
)
```

---

## 📌 Previous Month Customer Count

**Location**: Customer Overview\
**Type**: Supporting Measure

**Explanation**:\
Count of distinct customers from the previous month.

**DAX Formula**:

```DAX
Previous Month Customer Count =
VAR PrevMonth = CALCULATE(
    [Total Customer Count],
    DATEADD(dim_month[Month], -1, MONTH)
)
RETURN IF(ISBLANK(PrevMonth), BLANK(), PrevMonth)
```

---

## 📌 Retention Rate

**Location**: Customer Overview\
**Type**: Supporting Measure (Used in line chart)

**Explanation**:\
Monthly retention rate = Retained customers / Previous month customers.

**DAX Formula**:

```DAX
Retention Rate =
DIVIDE(
    CALCULATE(
        DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]),
        customer_retention_monthly_summary[is_retained] = 1
    ),
    CALCULATE(
        DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]),
        DATEADD(dim_month[Month], -1, MONTH)
    )
)
```

---

## 📌 New Customer Count

**Location**: Customer Overview\
**Type**: Supporting Measure

**Explanation**:\
Number of customers who placed their first order in the current month.

**DAX Formula**:

```DAX
New Customer Count =
CALCULATE(
    DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]),
    FILTER('customer_retention_monthly_summary', [is_new_customer] = 1)
)
```

---

## 📌 Consecutive Purchase Rate by Final Stage

**Location**: Customer Lifecycle & Behavior Analysis\
**Type**: Supporting Measure

**Explanation**:\
Proportion of customers who made a purchase in consecutive months, measured against total customers.

**DAX Formula**:

```DAX
Consecutive Purchase Rate by Final Stage =
DIVIDE(
    CALCULATE(
        DISTINCTCOUNT(customer_retention_monthly_summary[customer_id]),
        customer_retention_monthly_summary[is_retained] = 1
    ),
    CALCULATE(
        DISTINCTCOUNT(customer_retention_monthly_summary[customer_id])
    )
)
```

