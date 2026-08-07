/*
================================================================================
ARR SEMANTIC MODEL - ANALYTICAL VIEWS
================================================================================
Production views for dashboarding, reporting, and semantic layer consumption.
Author: Abhishek Suwalka
================================================================================
*/

USE SCHEMA ARR_ANALYTICS;


-- ============================================================================
-- VIEW 1: V_ARR_WATERFALL
-- Purpose: Monthly ARR bridge/waterfall. Shows how ARR moves from beginning
--          to ending each month by movement category.
-- Use: Executive dashboards, board decks, ARR bridge charts
-- ============================================================================
CREATE OR REPLACE VIEW V_ARR_WATERFALL AS
SELECT
    m.METRIC_MONTH,
    t.YEAR_MONTH,
    t.QUARTER_NAME,
    t.YEAR_NUM,
    m.BEGINNING_ARR,
    m.NEW_BUSINESS_ARR,
    m.EXPANSION_ARR,
    m.CONTRACTION_ARR,
    m.CHURN_ARR,
    m.RESURRECTION_ARR,
    m.FX_ADJUSTMENT_ARR,
    m.NET_NEW_ARR,
    m.ENDING_ARR,
    m.GROSS_RETENTION_RATE,
    m.NET_RETENTION_RATE,
    m.CUSTOMER_COUNT,
    m.NEW_CUSTOMERS,
    m.CHURNED_CUSTOMERS,
    m.LOGO_RETENTION_RATE
FROM FACT_ARR_METRICS m
JOIN DIM_TIME t ON m.DATE_KEY = t.DATE_KEY
ORDER BY m.METRIC_MONTH;


-- ============================================================================
-- VIEW 2: V_ARR_BY_CUSTOMER
-- Purpose: Current ARR per customer with full dimensional attributes.
--          Shows the latest snapshot for each active customer.
-- Use: Account-level analysis, customer health, sales rep performance
-- ============================================================================
CREATE OR REPLACE VIEW V_ARR_BY_CUSTOMER AS
WITH latest_snapshot AS (
    SELECT
        CUSTOMER_ID,
        SUM(ARR_AMOUNT) AS TOTAL_ARR,
        SUM(MRR_AMOUNT) AS TOTAL_MRR,
        COUNT(DISTINCT PRODUCT_ID) AS PRODUCT_COUNT,
        MAX(SNAPSHOT_DATE) AS SNAPSHOT_DATE
    FROM FACT_ARR_MONTHLY_SNAPSHOT
    WHERE SNAPSHOT_DATE = (SELECT MAX(SNAPSHOT_DATE) FROM FACT_ARR_MONTHLY_SNAPSHOT)
    GROUP BY CUSTOMER_ID
)
SELECT
    c.CUSTOMER_ID,
    c.CUSTOMER_NAME,
    c.INDUSTRY,
    c.SEGMENT,
    c.REGION,
    c.COUNTRY,
    c.ACCOUNT_OWNER,
    c.CUSTOMER_SINCE,
    c.CUSTOMER_STATUS,
    COALESCE(ls.TOTAL_ARR, 0) AS CURRENT_ARR,
    COALESCE(ls.TOTAL_MRR, 0) AS CURRENT_MRR,
    COALESCE(ls.PRODUCT_COUNT, 0) AS ACTIVE_PRODUCTS,
    DATEDIFF('month', c.CUSTOMER_SINCE, CURRENT_DATE()) AS TENURE_MONTHS,
    ls.SNAPSHOT_DATE AS AS_OF_DATE
FROM DIM_CUSTOMER c
LEFT JOIN latest_snapshot ls ON c.CUSTOMER_ID = ls.CUSTOMER_ID
WHERE c.CUSTOMER_STATUS = 'Active';


-- ============================================================================
-- VIEW 3: V_ARR_MOVEMENT_DETAIL
-- Purpose: Detailed movement fact enriched with customer, product, and
--          classification names. Full context for drill-down analysis.
-- Use: Movement detail tables, root cause analysis, sales attribution
-- ============================================================================
CREATE OR REPLACE VIEW V_ARR_MOVEMENT_DETAIL AS
SELECT
    mv.MOVEMENT_ID,
    mv.MOVEMENT_MONTH,
    t.YEAR_MONTH,
    t.QUARTER_NAME,
    t.YEAR_NUM,
    c.CUSTOMER_NAME,
    c.SEGMENT,
    c.REGION,
    c.ACCOUNT_OWNER,
    p.PRODUCT_NAME,
    p.PRODUCT_FAMILY,
    p.PRODUCT_TIER,
    cl.CLASSIFICATION_NAME,
    cl.CLASSIFICATION_GROUP,
    mv.PRIOR_ARR,
    mv.CURRENT_ARR,
    mv.ARR_DELTA,
    mv.MOVEMENT_REASON
FROM FACT_ARR_MOVEMENT mv
JOIN DIM_CUSTOMER c ON mv.CUSTOMER_ID = c.CUSTOMER_ID
JOIN DIM_TIME t ON mv.DATE_KEY = t.DATE_KEY
JOIN DIM_ARR_CLASSIFICATION cl ON mv.CLASSIFICATION_ID = cl.CLASSIFICATION_ID
LEFT JOIN DIM_PRODUCT p ON mv.PRODUCT_ID = p.PRODUCT_ID
ORDER BY mv.MOVEMENT_MONTH, cl.SORT_ORDER;


-- ============================================================================
-- VIEW 4: V_RETENTION_RATES
-- Purpose: Monthly and rolling retention rate analysis.
--          Computes trailing 12-month retention for trend smoothing.
-- Use: Retention trend charts, investor metrics, SaaS benchmarking
-- ============================================================================
CREATE OR REPLACE VIEW V_RETENTION_RATES AS
SELECT
    m.METRIC_MONTH,
    t.YEAR_MONTH,
    t.YEAR_NUM,
    t.QUARTER_NAME,
    m.BEGINNING_ARR,
    m.ENDING_ARR,
    m.GROSS_RETENTION_RATE,
    m.NET_RETENTION_RATE,
    m.LOGO_RETENTION_RATE,
    m.CUSTOMER_COUNT,
    -- Rolling 3-month averages
    AVG(m.GROSS_RETENTION_RATE) OVER (ORDER BY m.METRIC_MONTH ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS GRR_3M_AVG,
    AVG(m.NET_RETENTION_RATE) OVER (ORDER BY m.METRIC_MONTH ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS NRR_3M_AVG
FROM FACT_ARR_METRICS m
JOIN DIM_TIME t ON m.DATE_KEY = t.DATE_KEY
ORDER BY m.METRIC_MONTH;


-- ============================================================================
-- VIEW 5: V_ARR_COHORT
-- Purpose: Customer cohort retention analysis. Groups customers by their
--          start quarter and tracks ARR retention over time.
-- Use: Cohort charts, vintage analysis, product-market fit assessment
-- ============================================================================
CREATE OR REPLACE VIEW V_ARR_COHORT AS
WITH customer_cohort AS (
    SELECT
        c.CUSTOMER_ID,
        c.CUSTOMER_NAME,
        DATE_TRUNC('quarter', c.CUSTOMER_SINCE) AS COHORT_QUARTER,
        TO_CHAR(DATE_TRUNC('quarter', c.CUSTOMER_SINCE), 'YYYY-"Q"Q') AS COHORT_LABEL
    FROM DIM_CUSTOMER c
),
monthly_arr AS (
    SELECT
        s.CUSTOMER_ID,
        s.SNAPSHOT_DATE,
        SUM(s.ARR_AMOUNT) AS CUSTOMER_ARR
    FROM FACT_ARR_MONTHLY_SNAPSHOT s
    GROUP BY s.CUSTOMER_ID, s.SNAPSHOT_DATE
)
SELECT
    cc.COHORT_LABEL,
    cc.COHORT_QUARTER,
    ma.SNAPSHOT_DATE,
    DATEDIFF('month', cc.COHORT_QUARTER, ma.SNAPSHOT_DATE) AS MONTHS_SINCE_COHORT,
    COUNT(DISTINCT cc.CUSTOMER_ID) AS CUSTOMER_COUNT,
    SUM(ma.CUSTOMER_ARR) AS COHORT_ARR
FROM customer_cohort cc
JOIN monthly_arr ma ON cc.CUSTOMER_ID = ma.CUSTOMER_ID
GROUP BY cc.COHORT_LABEL, cc.COHORT_QUARTER, ma.SNAPSHOT_DATE
ORDER BY cc.COHORT_QUARTER, ma.SNAPSHOT_DATE;


-- ============================================================================
-- VIEW 6: V_ARR_BY_PRODUCT
-- Purpose: ARR breakdown by product family and tier.
-- Use: Product performance analysis, portfolio mix charts
-- ============================================================================
CREATE OR REPLACE VIEW V_ARR_BY_PRODUCT AS
SELECT
    s.SNAPSHOT_DATE,
    p.PRODUCT_ID,
    p.PRODUCT_NAME,
    p.PRODUCT_FAMILY,
    p.PRODUCT_TIER,
    COUNT(DISTINCT s.CUSTOMER_ID) AS CUSTOMER_COUNT,
    SUM(s.ARR_AMOUNT) AS TOTAL_ARR,
    SUM(s.MRR_AMOUNT) AS TOTAL_MRR
FROM FACT_ARR_MONTHLY_SNAPSHOT s
JOIN DIM_PRODUCT p ON s.PRODUCT_ID = p.PRODUCT_ID
GROUP BY s.SNAPSHOT_DATE, p.PRODUCT_ID, p.PRODUCT_NAME, p.PRODUCT_FAMILY, p.PRODUCT_TIER
ORDER BY s.SNAPSHOT_DATE, TOTAL_ARR DESC;


-- ============================================================================
-- VIEW 7: V_SUBSCRIPTION_HEALTH
-- Purpose: Active subscription overview with renewal risk indicators.
-- Use: Customer success dashboards, renewal forecasting
-- ============================================================================
CREATE OR REPLACE VIEW V_SUBSCRIPTION_HEALTH AS
SELECT
    sub.SUBSCRIPTION_ID,
    c.CUSTOMER_NAME,
    c.SEGMENT,
    c.REGION,
    p.PRODUCT_NAME,
    p.PRODUCT_FAMILY,
    sub.SUBSCRIPTION_STATUS,
    sub.START_DATE,
    sub.END_DATE,
    sub.ARR,
    sub.MRR,
    sub.AUTO_RENEW,
    DATEDIFF('day', CURRENT_DATE(), sub.END_DATE) AS DAYS_TO_RENEWAL,
    CASE
        WHEN DATEDIFF('day', CURRENT_DATE(), sub.END_DATE) <= 30 THEN 'Critical'
        WHEN DATEDIFF('day', CURRENT_DATE(), sub.END_DATE) <= 90 THEN 'Approaching'
        WHEN DATEDIFF('day', CURRENT_DATE(), sub.END_DATE) <= 180 THEN 'Upcoming'
        ELSE 'Healthy'
    END AS RENEWAL_RISK
FROM FACT_SUBSCRIPTION sub
JOIN DIM_CUSTOMER c ON sub.CUSTOMER_ID = c.CUSTOMER_ID
JOIN DIM_PRODUCT p ON sub.PRODUCT_ID = p.PRODUCT_ID
WHERE sub.SUBSCRIPTION_STATUS = 'Active'
ORDER BY DAYS_TO_RENEWAL;
