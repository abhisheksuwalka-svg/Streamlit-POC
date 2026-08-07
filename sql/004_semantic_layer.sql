/*
================================================================================
ARR SEMANTIC MODEL - SEMANTIC LAYER
================================================================================
Power BI / Streamlit-ready star schema views with pre-defined measures,
hierarchies, and display-friendly column names.
Author: Abhishek Suwalka
================================================================================
*/

USE SCHEMA ARR_ANALYTICS;


-- ============================================================================
-- SEMANTIC VIEW 1: SEM_FACT_ARR
-- Purpose: Central fact view for Power BI / BI tools. Denormalized star schema
--          with all dimensional attributes pre-joined for drag-and-drop analysis.
-- ============================================================================
CREATE OR REPLACE VIEW SEM_FACT_ARR AS
SELECT
    -- Keys
    mv.MOVEMENT_ID,
    mv.MOVEMENT_MONTH AS "Date",
    t.YEAR_MONTH AS "Year-Month",
    t.YEAR_NUM AS "Year",
    t.QUARTER_NAME AS "Quarter",
    t.MONTH_NAME AS "Month",
    t.MONTH_NUM AS "Month Number",
    t.FISCAL_YEAR AS "Fiscal Year",
    t.FISCAL_QUARTER AS "Fiscal Quarter",

    -- Customer dimension
    c.CUSTOMER_ID AS "Customer ID",
    c.CUSTOMER_NAME AS "Customer",
    c.INDUSTRY AS "Industry",
    c.SEGMENT AS "Segment",
    c.REGION AS "Region",
    c.COUNTRY AS "Country",
    c.ACCOUNT_OWNER AS "Account Owner",
    c.CUSTOMER_STATUS AS "Customer Status",

    -- Product dimension
    p.PRODUCT_ID AS "Product ID",
    p.PRODUCT_NAME AS "Product",
    p.PRODUCT_FAMILY AS "Product Family",
    p.PRODUCT_TIER AS "Product Tier",

    -- Classification dimension
    cl.CLASSIFICATION_NAME AS "Movement Type",
    cl.CLASSIFICATION_GROUP AS "Movement Category",

    -- Measures
    mv.PRIOR_ARR AS "Prior ARR",
    mv.CURRENT_ARR AS "Current ARR",
    mv.ARR_DELTA AS "ARR Change",
    ABS(mv.ARR_DELTA) AS "ARR Change (Absolute)",
    mv.MOVEMENT_REASON AS "Reason"

FROM FACT_ARR_MOVEMENT mv
JOIN DIM_TIME t ON mv.DATE_KEY = t.DATE_KEY
JOIN DIM_CUSTOMER c ON mv.CUSTOMER_ID = c.CUSTOMER_ID
JOIN DIM_ARR_CLASSIFICATION cl ON mv.CLASSIFICATION_ID = cl.CLASSIFICATION_ID
LEFT JOIN DIM_PRODUCT p ON mv.PRODUCT_ID = p.PRODUCT_ID;


-- ============================================================================
-- SEMANTIC VIEW 2: SEM_ARR_METRICS
-- Purpose: Monthly KPI view with display-friendly names for executive dashboards.
-- ============================================================================
CREATE OR REPLACE VIEW SEM_ARR_METRICS AS
SELECT
    m.METRIC_MONTH AS "Date",
    t.YEAR_MONTH AS "Year-Month",
    t.YEAR_NUM AS "Year",
    t.QUARTER_NAME AS "Quarter",
    t.MONTH_NAME AS "Month",

    -- ARR Measures
    m.BEGINNING_ARR AS "Beginning ARR",
    m.NEW_BUSINESS_ARR AS "New Business",
    m.EXPANSION_ARR AS "Expansion",
    m.CONTRACTION_ARR AS "Contraction",
    m.CHURN_ARR AS "Churn",
    m.RESURRECTION_ARR AS "Resurrection",
    m.FX_ADJUSTMENT_ARR AS "FX Adjustment",
    m.NET_NEW_ARR AS "Net New ARR",
    m.ENDING_ARR AS "Ending ARR",

    -- Retention Measures
    m.GROSS_RETENTION_RATE AS "Gross Retention Rate",
    m.NET_RETENTION_RATE AS "Net Retention Rate",
    m.LOGO_RETENTION_RATE AS "Logo Retention Rate",

    -- Customer Measures
    m.CUSTOMER_COUNT AS "Active Customers",
    m.NEW_CUSTOMERS AS "New Customers",
    m.CHURNED_CUSTOMERS AS "Churned Customers",

    -- Derived Measures
    m.ENDING_ARR - m.BEGINNING_ARR AS "ARR Growth",
    CASE WHEN m.BEGINNING_ARR > 0
         THEN (m.ENDING_ARR - m.BEGINNING_ARR) / m.BEGINNING_ARR
         ELSE 0
    END AS "Growth Rate",
    CASE WHEN m.CUSTOMER_COUNT > 0
         THEN m.ENDING_ARR / m.CUSTOMER_COUNT
         ELSE 0
    END AS "Avg ARR per Customer"

FROM FACT_ARR_METRICS m
JOIN DIM_TIME t ON m.DATE_KEY = t.DATE_KEY
ORDER BY m.METRIC_MONTH;


-- ============================================================================
-- SEMANTIC VIEW 3: SEM_CUSTOMER_ARR
-- Purpose: Customer-level ARR analysis with dimensional slicing.
--          Optimized for segment/region/industry breakdown charts.
-- ============================================================================
CREATE OR REPLACE VIEW SEM_CUSTOMER_ARR AS
SELECT
    s.SNAPSHOT_DATE AS "Date",
    c.CUSTOMER_ID AS "Customer ID",
    c.CUSTOMER_NAME AS "Customer",
    c.INDUSTRY AS "Industry",
    c.SEGMENT AS "Segment",
    c.REGION AS "Region",
    c.COUNTRY AS "Country",
    c.ACCOUNT_OWNER AS "Account Owner",
    DATEDIFF('month', c.CUSTOMER_SINCE, s.SNAPSHOT_DATE) AS "Tenure (Months)",
    p.PRODUCT_NAME AS "Product",
    p.PRODUCT_FAMILY AS "Product Family",
    p.PRODUCT_TIER AS "Product Tier",
    s.ARR_AMOUNT AS "ARR",
    s.MRR_AMOUNT AS "MRR",
    s.QUANTITY AS "Quantity"
FROM FACT_ARR_MONTHLY_SNAPSHOT s
JOIN DIM_CUSTOMER c ON s.CUSTOMER_ID = c.CUSTOMER_ID
JOIN DIM_PRODUCT p ON s.PRODUCT_ID = p.PRODUCT_ID;


-- ============================================================================
-- SEMANTIC VIEW 4: SEM_QUARTERLY_METRICS
-- Purpose: Board-level quarterly and annual metrics for strategic dashboards.
-- ============================================================================
CREATE OR REPLACE VIEW SEM_QUARTERLY_METRICS AS
SELECT
    PERIOD_KEY AS "Period",
    PERIOD_TYPE AS "Period Type",
    PERIOD_START_DATE AS "Start Date",
    PERIOD_END_DATE AS "End Date",
    BEGINNING_ARR AS "Beginning ARR",
    ENDING_ARR AS "Ending ARR",
    NET_NEW_ARR AS "Net New ARR",
    ARR_GROWTH_RATE AS "Growth Rate",
    GROSS_RETENTION_RATE AS "Gross Retention",
    NET_RETENTION_RATE AS "Net Retention",
    LOGO_RETENTION_RATE AS "Logo Retention",
    AVG_ARR_PER_CUSTOMER AS "Avg ARR / Customer",
    TOTAL_CUSTOMERS AS "Total Customers",
    NEW_LOGOS AS "New Logos",
    CHURNED_LOGOS AS "Churned Logos",
    QUICK_RATIO AS "Quick Ratio"
FROM FACT_ARR_FINAL_METRICS
ORDER BY PERIOD_START_DATE;


-- ============================================================================
-- SEMANTIC VIEW 5: SEM_SUBSCRIPTION_RENEWALS
-- Purpose: Renewal pipeline view for customer success and forecasting.
-- ============================================================================
CREATE OR REPLACE VIEW SEM_SUBSCRIPTION_RENEWALS AS
SELECT
    c.CUSTOMER_NAME AS "Customer",
    c.SEGMENT AS "Segment",
    c.REGION AS "Region",
    c.ACCOUNT_OWNER AS "Account Owner",
    p.PRODUCT_NAME AS "Product",
    p.PRODUCT_FAMILY AS "Product Family",
    sub.ARR AS "ARR at Risk",
    sub.MRR AS "MRR",
    sub.START_DATE AS "Start Date",
    sub.END_DATE AS "End Date",
    sub.AUTO_RENEW AS "Auto Renew",
    DATEDIFF('day', CURRENT_DATE(), sub.END_DATE) AS "Days to Renewal",
    CASE
        WHEN DATEDIFF('day', CURRENT_DATE(), sub.END_DATE) <= 30 THEN '1 - Critical (≤30d)'
        WHEN DATEDIFF('day', CURRENT_DATE(), sub.END_DATE) <= 60 THEN '2 - Urgent (≤60d)'
        WHEN DATEDIFF('day', CURRENT_DATE(), sub.END_DATE) <= 90 THEN '3 - Approaching (≤90d)'
        WHEN DATEDIFF('day', CURRENT_DATE(), sub.END_DATE) <= 180 THEN '4 - Upcoming (≤180d)'
        ELSE '5 - Healthy (>180d)'
    END AS "Renewal Risk",
    DATE_TRUNC('month', sub.END_DATE) AS "Renewal Month",
    DATE_TRUNC('quarter', sub.END_DATE) AS "Renewal Quarter"
FROM FACT_SUBSCRIPTION sub
JOIN DIM_CUSTOMER c ON sub.CUSTOMER_ID = c.CUSTOMER_ID
JOIN DIM_PRODUCT p ON sub.PRODUCT_ID = p.PRODUCT_ID
WHERE sub.SUBSCRIPTION_STATUS = 'Active'
ORDER BY sub.END_DATE;


-- ============================================================================
-- POWER BI MEASURES REFERENCE (DAX equivalents documented as comments)
-- These are implemented in the BI tool, documented here for reference.
-- ============================================================================

/*
POWER BI MEASURE DEFINITIONS (for import into Power BI model):

Beginning ARR = CALCULATE(SUM('SEM_ARR_METRICS'[Beginning ARR]), LASTDATE('SEM_ARR_METRICS'[Date]))
Ending ARR = CALCULATE(SUM('SEM_ARR_METRICS'[Ending ARR]), LASTDATE('SEM_ARR_METRICS'[Date]))
Net New ARR = SUM('SEM_ARR_METRICS'[Net New ARR])
New Business = SUM('SEM_ARR_METRICS'[New Business])
Expansion = SUM('SEM_ARR_METRICS'[Expansion])
Contraction = SUM('SEM_ARR_METRICS'[Contraction])
Churn = SUM('SEM_ARR_METRICS'[Churn])
GRR = AVERAGE('SEM_ARR_METRICS'[Gross Retention Rate])
NRR = AVERAGE('SEM_ARR_METRICS'[Net Retention Rate])
Quick Ratio = DIVIDE(([New Business] + [Expansion]), ABS([Contraction] + [Churn]))

HIERARCHIES:
- Time: Year > Quarter > Month
- Geography: Region > Country
- Product: Product Family > Product Tier > Product
- Customer: Segment > Industry > Customer
- Movement: Movement Category > Movement Type
*/
