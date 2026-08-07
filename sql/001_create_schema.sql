/*
================================================================================
ARR SEMANTIC MODEL - SCHEMA DEFINITION
================================================================================
Standalone ARR (Annual Recurring Revenue) analytics warehouse.
No external dependencies. Production-ready star schema.

Schema: ARR_ANALYTICS
Tables: 12
Author: Abhishek Suwalka
================================================================================
*/

-- ============================================================================
-- SCHEMA
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS ARR_ANALYTICS
    COMMENT = 'Production ARR semantic model for recurring revenue analytics';

USE SCHEMA ARR_ANALYTICS;


-- ============================================================================
-- TABLE 1: DIM_CUSTOMER
-- Purpose: Master customer dimension. Central entity for all ARR attribution.
-- Connects to: FACT_CONTRACT, FACT_SUBSCRIPTION, FACT_ARR_MONTHLY_SNAPSHOT,
--              FACT_ARR_MOVEMENT, FACT_ARR_ADJUSTMENT
-- ============================================================================
CREATE OR REPLACE TABLE DIM_CUSTOMER (
    CUSTOMER_ID         VARCHAR(20)     NOT NULL,
    CUSTOMER_NAME       VARCHAR(200)    NOT NULL,
    INDUSTRY            VARCHAR(100),
    SEGMENT             VARCHAR(50)     NOT NULL    COMMENT 'Enterprise / Mid-Market / SMB',
    REGION              VARCHAR(50)     NOT NULL    COMMENT 'North America / EMEA / APAC / LATAM',
    COUNTRY             VARCHAR(100),
    ACCOUNT_OWNER       VARCHAR(100),
    CUSTOMER_SINCE      DATE            NOT NULL,
    CUSTOMER_STATUS     VARCHAR(20)     NOT NULL    DEFAULT 'Active' COMMENT 'Active / Churned / Paused',
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_DIM_CUSTOMER PRIMARY KEY (CUSTOMER_ID)
)
COMMENT = 'Customer master dimension - one row per unique customer account';


-- ============================================================================
-- TABLE 2: DIM_PRODUCT
-- Purpose: Product catalog. Defines what is sold and at what tier/price.
-- Connects to: FACT_CONTRACT_LINE, FACT_SUBSCRIPTION, FACT_ARR_MONTHLY_SNAPSHOT
-- ============================================================================
CREATE OR REPLACE TABLE DIM_PRODUCT (
    PRODUCT_ID          VARCHAR(20)     NOT NULL,
    PRODUCT_NAME        VARCHAR(200)    NOT NULL,
    PRODUCT_FAMILY      VARCHAR(100)    NOT NULL    COMMENT 'Platform / Analytics / Security / Integration',
    PRODUCT_TIER        VARCHAR(50)     NOT NULL    COMMENT 'Starter / Professional / Enterprise',
    LIST_PRICE_ANNUAL   NUMBER(12,2)    NOT NULL    COMMENT 'Annual list price per unit',
    IS_ACTIVE           BOOLEAN         DEFAULT TRUE,
    LAUNCH_DATE         DATE,
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_DIM_PRODUCT PRIMARY KEY (PRODUCT_ID)
)
COMMENT = 'Product catalog dimension - defines sellable SKUs and pricing tiers';


-- ============================================================================
-- TABLE 3: DIM_TIME
-- Purpose: Calendar/date dimension for time-based analysis. Enables fiscal
--          year alignment, monthly/quarterly aggregations, and YoY comparisons.
-- Connects to: All fact tables via date keys
-- ============================================================================
CREATE OR REPLACE TABLE DIM_TIME (
    DATE_KEY            NUMBER(8)       NOT NULL    COMMENT 'YYYYMMDD integer key',
    FULL_DATE           DATE            NOT NULL,
    DAY_OF_MONTH        NUMBER(2),
    DAY_OF_WEEK         NUMBER(1),
    DAY_NAME            VARCHAR(10),
    MONTH_NUM           NUMBER(2),
    MONTH_NAME          VARCHAR(10),
    MONTH_SHORT         VARCHAR(3),
    QUARTER_NUM         NUMBER(1),
    QUARTER_NAME        VARCHAR(6)      COMMENT 'Q1, Q2, Q3, Q4',
    YEAR_NUM            NUMBER(4),
    YEAR_MONTH          VARCHAR(7)      COMMENT 'YYYY-MM format',
    YEAR_QUARTER        VARCHAR(7)      COMMENT 'YYYY-Q# format',
    FISCAL_YEAR         NUMBER(4)       COMMENT 'Feb-Jan fiscal year',
    FISCAL_QUARTER      NUMBER(1),
    IS_MONTH_END        BOOLEAN,
    IS_QUARTER_END      BOOLEAN,
    IS_YEAR_END         BOOLEAN,

    CONSTRAINT PK_DIM_TIME PRIMARY KEY (DATE_KEY)
)
COMMENT = 'Calendar dimension - supports calendar and fiscal year analytics';


-- ============================================================================
-- TABLE 4: DIM_ARR_CLASSIFICATION
-- Purpose: Lookup table for ARR movement categories. Standardizes how revenue
--          changes are classified across the organization.
-- Connects to: FACT_ARR_MOVEMENT
-- ============================================================================
CREATE OR REPLACE TABLE DIM_ARR_CLASSIFICATION (
    CLASSIFICATION_ID   VARCHAR(10)     NOT NULL,
    CLASSIFICATION_NAME VARCHAR(50)     NOT NULL,
    CLASSIFICATION_GROUP VARCHAR(30)    NOT NULL    COMMENT 'Growth / Contraction / Adjustment',
    IMPACT_SIGN         NUMBER(1)       NOT NULL    COMMENT '1 = positive, -1 = negative',
    SORT_ORDER          NUMBER(2)       NOT NULL,
    DESCRIPTION         VARCHAR(500),

    CONSTRAINT PK_DIM_ARR_CLASSIFICATION PRIMARY KEY (CLASSIFICATION_ID)
)
COMMENT = 'ARR movement classification lookup - New, Expansion, Contraction, Churn, Resurrection, FX';


-- ============================================================================
-- TABLE 5: FACT_CONTRACT
-- Purpose: Master contract records. One row per signed agreement.
--          Tracks contract lifecycle from signature to renewal/termination.
-- Connects to: DIM_CUSTOMER (FK), FACT_CONTRACT_LINE (parent)
-- ============================================================================
CREATE OR REPLACE TABLE FACT_CONTRACT (
    CONTRACT_ID         VARCHAR(20)     NOT NULL,
    CUSTOMER_ID         VARCHAR(20)     NOT NULL,
    CONTRACT_NAME       VARCHAR(200),
    CONTRACT_STATUS     VARCHAR(20)     NOT NULL    COMMENT 'Active / Expired / Terminated / Pending',
    CONTRACT_START_DATE DATE            NOT NULL,
    CONTRACT_END_DATE   DATE            NOT NULL,
    CONTRACT_TERM_MONTHS NUMBER(3)      NOT NULL    COMMENT 'Duration in months (12, 24, 36)',
    TOTAL_CONTRACT_VALUE NUMBER(14,2)   NOT NULL    COMMENT 'TCV - Total Contract Value',
    ANNUAL_CONTRACT_VALUE NUMBER(14,2)  NOT NULL    COMMENT 'ACV - Annual Contract Value',
    PAYMENT_FREQUENCY   VARCHAR(20)     DEFAULT 'Annual' COMMENT 'Monthly / Quarterly / Annual',
    SIGNED_DATE         DATE,
    RENEWAL_TYPE        VARCHAR(20)     DEFAULT 'Auto' COMMENT 'Auto / Manual / None',
    SALES_REP           VARCHAR(100),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_FACT_CONTRACT PRIMARY KEY (CONTRACT_ID),
    CONSTRAINT FK_CONTRACT_CUSTOMER FOREIGN KEY (CUSTOMER_ID) REFERENCES DIM_CUSTOMER(CUSTOMER_ID)
)
COMMENT = 'Contract fact table - one row per signed customer agreement';


-- ============================================================================
-- TABLE 6: FACT_CONTRACT_LINE
-- Purpose: Line-item detail within contracts. Each line represents a specific
--          product/SKU purchased with quantity, pricing, and ARR contribution.
-- Connects to: FACT_CONTRACT (FK), DIM_PRODUCT (FK)
-- ============================================================================
CREATE OR REPLACE TABLE FACT_CONTRACT_LINE (
    CONTRACT_LINE_ID    VARCHAR(20)     NOT NULL,
    CONTRACT_ID         VARCHAR(20)     NOT NULL,
    PRODUCT_ID          VARCHAR(20)     NOT NULL,
    LINE_STATUS         VARCHAR(20)     NOT NULL    DEFAULT 'Active' COMMENT 'Active / Cancelled / Upgraded',
    QUANTITY            NUMBER(6)       NOT NULL    DEFAULT 1,
    UNIT_PRICE_ANNUAL   NUMBER(12,2)    NOT NULL    COMMENT 'Negotiated annual price per unit',
    DISCOUNT_PERCENT    NUMBER(5,2)     DEFAULT 0,
    LINE_ARR            NUMBER(14,2)    NOT NULL    COMMENT 'ARR = Quantity * Unit_Price * (1 - Discount)',
    LINE_START_DATE     DATE            NOT NULL,
    LINE_END_DATE       DATE            NOT NULL,
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_FACT_CONTRACT_LINE PRIMARY KEY (CONTRACT_LINE_ID),
    CONSTRAINT FK_LINE_CONTRACT FOREIGN KEY (CONTRACT_ID) REFERENCES FACT_CONTRACT(CONTRACT_ID),
    CONSTRAINT FK_LINE_PRODUCT FOREIGN KEY (PRODUCT_ID) REFERENCES DIM_PRODUCT(PRODUCT_ID)
)
COMMENT = 'Contract line items - product-level detail with pricing and ARR';


-- ============================================================================
-- TABLE 7: FACT_SUBSCRIPTION
-- Purpose: Active/historical subscriptions. Represents the ongoing delivery
--          of service to a customer. Links contracts to recurring revenue.
-- Connects to: DIM_CUSTOMER (FK), FACT_CONTRACT_LINE (FK), DIM_PRODUCT (FK)
-- ============================================================================
CREATE OR REPLACE TABLE FACT_SUBSCRIPTION (
    SUBSCRIPTION_ID     VARCHAR(20)     NOT NULL,
    CUSTOMER_ID         VARCHAR(20)     NOT NULL,
    CONTRACT_LINE_ID    VARCHAR(20)     NOT NULL,
    PRODUCT_ID          VARCHAR(20)     NOT NULL,
    SUBSCRIPTION_STATUS VARCHAR(20)     NOT NULL    COMMENT 'Active / Cancelled / Expired / Suspended',
    START_DATE          DATE            NOT NULL,
    END_DATE            DATE,
    MRR                 NUMBER(12,2)    NOT NULL    COMMENT 'Monthly Recurring Revenue',
    ARR                 NUMBER(14,2)    NOT NULL    COMMENT 'Annual Recurring Revenue = MRR * 12',
    QUANTITY            NUMBER(6)       DEFAULT 1,
    AUTO_RENEW          BOOLEAN         DEFAULT TRUE,
    CANCELLATION_DATE   DATE,
    CANCELLATION_REASON VARCHAR(200),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_FACT_SUBSCRIPTION PRIMARY KEY (SUBSCRIPTION_ID),
    CONSTRAINT FK_SUB_CUSTOMER FOREIGN KEY (CUSTOMER_ID) REFERENCES DIM_CUSTOMER(CUSTOMER_ID),
    CONSTRAINT FK_SUB_CONTRACT_LINE FOREIGN KEY (CONTRACT_LINE_ID) REFERENCES FACT_CONTRACT_LINE(CONTRACT_LINE_ID),
    CONSTRAINT FK_SUB_PRODUCT FOREIGN KEY (PRODUCT_ID) REFERENCES DIM_PRODUCT(PRODUCT_ID)
)
COMMENT = 'Subscription fact - active recurring service delivery with MRR/ARR';


-- ============================================================================
-- TABLE 8: FACT_ARR_MONTHLY_SNAPSHOT
-- Purpose: Point-in-time ARR snapshot at month end. Captures the state of
--          each customer-product ARR as of the last day of each month.
--          Foundation for all time-series ARR analysis.
-- Connects to: DIM_CUSTOMER (FK), DIM_PRODUCT (FK), DIM_TIME (via date key)
-- ============================================================================
CREATE OR REPLACE TABLE FACT_ARR_MONTHLY_SNAPSHOT (
    SNAPSHOT_ID         VARCHAR(30)     NOT NULL,
    SNAPSHOT_DATE       DATE            NOT NULL    COMMENT 'Last day of the month',
    DATE_KEY            NUMBER(8)       NOT NULL,
    CUSTOMER_ID         VARCHAR(20)     NOT NULL,
    PRODUCT_ID          VARCHAR(20)     NOT NULL,
    SUBSCRIPTION_ID     VARCHAR(20),
    ARR_AMOUNT          NUMBER(14,2)    NOT NULL,
    MRR_AMOUNT          NUMBER(12,2)    NOT NULL,
    QUANTITY            NUMBER(6)       DEFAULT 1,
    CURRENCY_CODE       VARCHAR(3)      DEFAULT 'USD',
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_FACT_ARR_SNAPSHOT PRIMARY KEY (SNAPSHOT_ID),
    CONSTRAINT FK_SNAP_CUSTOMER FOREIGN KEY (CUSTOMER_ID) REFERENCES DIM_CUSTOMER(CUSTOMER_ID),
    CONSTRAINT FK_SNAP_PRODUCT FOREIGN KEY (PRODUCT_ID) REFERENCES DIM_PRODUCT(PRODUCT_ID),
    CONSTRAINT FK_SNAP_TIME FOREIGN KEY (DATE_KEY) REFERENCES DIM_TIME(DATE_KEY)
)
COMMENT = 'Monthly ARR snapshot - point-in-time ARR state per customer-product';


-- ============================================================================
-- TABLE 9: FACT_ARR_MOVEMENT
-- Purpose: Month-over-month ARR changes classified by movement type.
--          Drives the ARR waterfall/bridge analysis. Each row represents
--          a specific ARR delta attributed to a classification.
-- Connects to: DIM_CUSTOMER (FK), DIM_PRODUCT (FK), DIM_ARR_CLASSIFICATION (FK)
-- ============================================================================
CREATE OR REPLACE TABLE FACT_ARR_MOVEMENT (
    MOVEMENT_ID         VARCHAR(30)     NOT NULL,
    MOVEMENT_MONTH      DATE            NOT NULL    COMMENT 'First day of the month the movement is recognized',
    DATE_KEY            NUMBER(8)       NOT NULL,
    CUSTOMER_ID         VARCHAR(20)     NOT NULL,
    PRODUCT_ID          VARCHAR(20),
    CLASSIFICATION_ID   VARCHAR(10)     NOT NULL,
    PRIOR_ARR           NUMBER(14,2)    DEFAULT 0   COMMENT 'ARR at prior month end',
    CURRENT_ARR         NUMBER(14,2)    DEFAULT 0   COMMENT 'ARR at current month end',
    ARR_DELTA           NUMBER(14,2)    NOT NULL    COMMENT 'Change in ARR (positive or negative)',
    MOVEMENT_REASON     VARCHAR(500),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_FACT_ARR_MOVEMENT PRIMARY KEY (MOVEMENT_ID),
    CONSTRAINT FK_MOV_CUSTOMER FOREIGN KEY (CUSTOMER_ID) REFERENCES DIM_CUSTOMER(CUSTOMER_ID),
    CONSTRAINT FK_MOV_PRODUCT FOREIGN KEY (PRODUCT_ID) REFERENCES DIM_PRODUCT(PRODUCT_ID),
    CONSTRAINT FK_MOV_CLASSIFICATION FOREIGN KEY (CLASSIFICATION_ID) REFERENCES DIM_ARR_CLASSIFICATION(CLASSIFICATION_ID),
    CONSTRAINT FK_MOV_TIME FOREIGN KEY (DATE_KEY) REFERENCES DIM_TIME(DATE_KEY)
)
COMMENT = 'ARR movement fact - classified month-over-month ARR changes (waterfall)';


-- ============================================================================
-- TABLE 10: FACT_ARR_ADJUSTMENT
-- Purpose: Manual or system-driven ARR adjustments outside normal movements.
--          Covers corrections, credits, FX adjustments, and one-time changes.
-- Connects to: DIM_CUSTOMER (FK)
-- ============================================================================
CREATE OR REPLACE TABLE FACT_ARR_ADJUSTMENT (
    ADJUSTMENT_ID       VARCHAR(20)     NOT NULL,
    ADJUSTMENT_DATE     DATE            NOT NULL,
    DATE_KEY            NUMBER(8)       NOT NULL,
    CUSTOMER_ID         VARCHAR(20)     NOT NULL,
    ADJUSTMENT_TYPE     VARCHAR(50)     NOT NULL    COMMENT 'FX / Credit / Correction / Migration',
    ADJUSTMENT_REASON   VARCHAR(500),
    ARR_AMOUNT          NUMBER(14,2)    NOT NULL    COMMENT 'Positive = increase, Negative = decrease',
    APPROVED_BY         VARCHAR(100),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_FACT_ARR_ADJUSTMENT PRIMARY KEY (ADJUSTMENT_ID),
    CONSTRAINT FK_ADJ_CUSTOMER FOREIGN KEY (CUSTOMER_ID) REFERENCES DIM_CUSTOMER(CUSTOMER_ID),
    CONSTRAINT FK_ADJ_TIME FOREIGN KEY (DATE_KEY) REFERENCES DIM_TIME(DATE_KEY)
)
COMMENT = 'ARR adjustments - manual corrections, FX, credits outside normal movement flow';


-- ============================================================================
-- TABLE 11: FACT_ARR_METRICS
-- Purpose: Pre-aggregated monthly ARR KPIs. Single source of truth for
--          executive reporting. Eliminates recomputation of complex metrics.
-- Connects to: DIM_TIME (via date key)
-- ============================================================================
CREATE OR REPLACE TABLE FACT_ARR_METRICS (
    METRIC_MONTH        DATE            NOT NULL    COMMENT 'First day of the month',
    DATE_KEY            NUMBER(8)       NOT NULL,
    BEGINNING_ARR       NUMBER(14,2)    NOT NULL,
    NEW_BUSINESS_ARR    NUMBER(14,2)    NOT NULL,
    EXPANSION_ARR       NUMBER(14,2)    NOT NULL,
    CONTRACTION_ARR     NUMBER(14,2)    NOT NULL    COMMENT 'Negative value',
    CHURN_ARR           NUMBER(14,2)    NOT NULL    COMMENT 'Negative value',
    RESURRECTION_ARR    NUMBER(14,2)    DEFAULT 0,
    FX_ADJUSTMENT_ARR   NUMBER(14,2)    DEFAULT 0,
    NET_NEW_ARR         NUMBER(14,2)    NOT NULL    COMMENT 'Sum of all movements',
    ENDING_ARR          NUMBER(14,2)    NOT NULL,
    GROSS_RETENTION_RATE NUMBER(7,4)    COMMENT 'GRR = (Begin + Contraction + Churn) / Begin',
    NET_RETENTION_RATE  NUMBER(7,4)     COMMENT 'NRR = (Begin + all movements excl new) / Begin',
    CUSTOMER_COUNT      NUMBER(6),
    NEW_CUSTOMERS       NUMBER(6),
    CHURNED_CUSTOMERS   NUMBER(6),
    LOGO_RETENTION_RATE NUMBER(7,4),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_FACT_ARR_METRICS PRIMARY KEY (METRIC_MONTH),
    CONSTRAINT FK_METRICS_TIME FOREIGN KEY (DATE_KEY) REFERENCES DIM_TIME(DATE_KEY)
)
COMMENT = 'Pre-aggregated monthly ARR metrics - executive KPIs and retention rates';


-- ============================================================================
-- TABLE 12: FACT_ARR_FINAL_METRICS
-- Purpose: Quarterly and annual strategic metrics. Higher-level aggregations
--          for board reporting, investor decks, and long-term trend analysis.
-- Connects to: Standalone rollup table
-- ============================================================================
CREATE OR REPLACE TABLE FACT_ARR_FINAL_METRICS (
    PERIOD_KEY          VARCHAR(10)     NOT NULL    COMMENT 'YYYY-Q# or YYYY',
    PERIOD_TYPE         VARCHAR(10)     NOT NULL    COMMENT 'Quarter / Annual',
    PERIOD_START_DATE   DATE            NOT NULL,
    PERIOD_END_DATE     DATE            NOT NULL,
    BEGINNING_ARR       NUMBER(14,2)    NOT NULL,
    ENDING_ARR          NUMBER(14,2)    NOT NULL,
    NET_NEW_ARR         NUMBER(14,2)    NOT NULL,
    ARR_GROWTH_RATE     NUMBER(7,4)     COMMENT 'Period-over-period growth %',
    GROSS_RETENTION_RATE NUMBER(7,4),
    NET_RETENTION_RATE  NUMBER(7,4),
    LOGO_RETENTION_RATE NUMBER(7,4),
    AVG_ARR_PER_CUSTOMER NUMBER(14,2),
    TOTAL_CUSTOMERS     NUMBER(6),
    NEW_LOGOS           NUMBER(6),
    CHURNED_LOGOS       NUMBER(6),
    QUICK_RATIO         NUMBER(7,4)     COMMENT '(New + Expansion) / (Contraction + Churn)',
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_FACT_ARR_FINAL PRIMARY KEY (PERIOD_KEY)
)
COMMENT = 'Quarterly/annual strategic ARR metrics - board-level KPIs and growth analysis';
