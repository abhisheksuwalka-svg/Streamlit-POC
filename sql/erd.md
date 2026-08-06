# ARR Semantic Model - Entity Relationship Diagram

## ER Diagram (Mermaid)

```mermaid
erDiagram
    DIM_CUSTOMER {
        varchar CUSTOMER_ID PK
        varchar CUSTOMER_NAME
        varchar INDUSTRY
        varchar SEGMENT
        varchar REGION
        varchar COUNTRY
        varchar ACCOUNT_OWNER
        date CUSTOMER_SINCE
        varchar CUSTOMER_STATUS
    }

    DIM_PRODUCT {
        varchar PRODUCT_ID PK
        varchar PRODUCT_NAME
        varchar PRODUCT_FAMILY
        varchar PRODUCT_TIER
        number LIST_PRICE_ANNUAL
        boolean IS_ACTIVE
        date LAUNCH_DATE
    }

    DIM_TIME {
        number DATE_KEY PK
        date FULL_DATE
        number MONTH_NUM
        varchar MONTH_NAME
        number QUARTER_NUM
        varchar QUARTER_NAME
        number YEAR_NUM
        varchar YEAR_MONTH
        number FISCAL_YEAR
        boolean IS_MONTH_END
    }

    DIM_ARR_CLASSIFICATION {
        varchar CLASSIFICATION_ID PK
        varchar CLASSIFICATION_NAME
        varchar CLASSIFICATION_GROUP
        number IMPACT_SIGN
        number SORT_ORDER
    }

    FACT_CONTRACT {
        varchar CONTRACT_ID PK
        varchar CUSTOMER_ID FK
        varchar CONTRACT_STATUS
        date CONTRACT_START_DATE
        date CONTRACT_END_DATE
        number TOTAL_CONTRACT_VALUE
        number ANNUAL_CONTRACT_VALUE
        varchar SALES_REP
    }

    FACT_CONTRACT_LINE {
        varchar CONTRACT_LINE_ID PK
        varchar CONTRACT_ID FK
        varchar PRODUCT_ID FK
        number QUANTITY
        number UNIT_PRICE_ANNUAL
        number LINE_ARR
        date LINE_START_DATE
        date LINE_END_DATE
    }

    FACT_SUBSCRIPTION {
        varchar SUBSCRIPTION_ID PK
        varchar CUSTOMER_ID FK
        varchar CONTRACT_LINE_ID FK
        varchar PRODUCT_ID FK
        varchar SUBSCRIPTION_STATUS
        number MRR
        number ARR
        date START_DATE
        date END_DATE
    }

    FACT_ARR_MONTHLY_SNAPSHOT {
        varchar SNAPSHOT_ID PK
        date SNAPSHOT_DATE
        number DATE_KEY FK
        varchar CUSTOMER_ID FK
        varchar PRODUCT_ID FK
        number ARR_AMOUNT
        number MRR_AMOUNT
    }

    FACT_ARR_MOVEMENT {
        varchar MOVEMENT_ID PK
        date MOVEMENT_MONTH
        number DATE_KEY FK
        varchar CUSTOMER_ID FK
        varchar PRODUCT_ID FK
        varchar CLASSIFICATION_ID FK
        number PRIOR_ARR
        number CURRENT_ARR
        number ARR_DELTA
    }

    FACT_ARR_ADJUSTMENT {
        varchar ADJUSTMENT_ID PK
        date ADJUSTMENT_DATE
        number DATE_KEY FK
        varchar CUSTOMER_ID FK
        varchar ADJUSTMENT_TYPE
        number ARR_AMOUNT
    }

    FACT_ARR_METRICS {
        date METRIC_MONTH PK
        number DATE_KEY FK
        number BEGINNING_ARR
        number ENDING_ARR
        number NET_NEW_ARR
        number GROSS_RETENTION_RATE
        number NET_RETENTION_RATE
    }

    FACT_ARR_FINAL_METRICS {
        varchar PERIOD_KEY PK
        varchar PERIOD_TYPE
        number BEGINNING_ARR
        number ENDING_ARR
        number ARR_GROWTH_RATE
        number QUICK_RATIO
    }

    %% Relationships
    DIM_CUSTOMER ||--o{ FACT_CONTRACT : "signs"
    DIM_CUSTOMER ||--o{ FACT_SUBSCRIPTION : "subscribes"
    DIM_CUSTOMER ||--o{ FACT_ARR_MONTHLY_SNAPSHOT : "has ARR"
    DIM_CUSTOMER ||--o{ FACT_ARR_MOVEMENT : "generates"
    DIM_CUSTOMER ||--o{ FACT_ARR_ADJUSTMENT : "receives"

    DIM_PRODUCT ||--o{ FACT_CONTRACT_LINE : "sold as"
    DIM_PRODUCT ||--o{ FACT_SUBSCRIPTION : "delivered via"
    DIM_PRODUCT ||--o{ FACT_ARR_MONTHLY_SNAPSHOT : "contributes"
    DIM_PRODUCT ||--o{ FACT_ARR_MOVEMENT : "drives"

    DIM_TIME ||--o{ FACT_ARR_MONTHLY_SNAPSHOT : "snapshot at"
    DIM_TIME ||--o{ FACT_ARR_MOVEMENT : "occurs in"
    DIM_TIME ||--o{ FACT_ARR_ADJUSTMENT : "applied on"
    DIM_TIME ||--o{ FACT_ARR_METRICS : "measured in"

    DIM_ARR_CLASSIFICATION ||--o{ FACT_ARR_MOVEMENT : "classifies"

    FACT_CONTRACT ||--o{ FACT_CONTRACT_LINE : "contains"
    FACT_CONTRACT_LINE ||--o{ FACT_SUBSCRIPTION : "activates"
```

---

## Relationship Mapping

| From Table | To Table | FK Column | Cardinality | Description |
|------------|----------|-----------|-------------|-------------|
| FACT_CONTRACT | DIM_CUSTOMER | CUSTOMER_ID | Many:1 | Each contract belongs to one customer |
| FACT_CONTRACT_LINE | FACT_CONTRACT | CONTRACT_ID | Many:1 | Each line belongs to one contract |
| FACT_CONTRACT_LINE | DIM_PRODUCT | PRODUCT_ID | Many:1 | Each line is for one product |
| FACT_SUBSCRIPTION | DIM_CUSTOMER | CUSTOMER_ID | Many:1 | Each subscription serves one customer |
| FACT_SUBSCRIPTION | FACT_CONTRACT_LINE | CONTRACT_LINE_ID | Many:1 | Each subscription maps to one contract line |
| FACT_SUBSCRIPTION | DIM_PRODUCT | PRODUCT_ID | Many:1 | Each subscription delivers one product |
| FACT_ARR_MONTHLY_SNAPSHOT | DIM_CUSTOMER | CUSTOMER_ID | Many:1 | Snapshot attributed to one customer |
| FACT_ARR_MONTHLY_SNAPSHOT | DIM_PRODUCT | PRODUCT_ID | Many:1 | Snapshot for one product |
| FACT_ARR_MONTHLY_SNAPSHOT | DIM_TIME | DATE_KEY | Many:1 | Snapshot as of one date |
| FACT_ARR_MOVEMENT | DIM_CUSTOMER | CUSTOMER_ID | Many:1 | Movement from one customer |
| FACT_ARR_MOVEMENT | DIM_PRODUCT | PRODUCT_ID | Many:1 | Movement for one product |
| FACT_ARR_MOVEMENT | DIM_ARR_CLASSIFICATION | CLASSIFICATION_ID | Many:1 | Movement classified as one type |
| FACT_ARR_MOVEMENT | DIM_TIME | DATE_KEY | Many:1 | Movement in one period |
| FACT_ARR_ADJUSTMENT | DIM_CUSTOMER | CUSTOMER_ID | Many:1 | Adjustment for one customer |
| FACT_ARR_ADJUSTMENT | DIM_TIME | DATE_KEY | Many:1 | Adjustment in one period |
| FACT_ARR_METRICS | DIM_TIME | DATE_KEY | 1:1 | One metrics row per month |

---

## Table Purpose Summary

| # | Table | Type | Purpose |
|---|-------|------|---------|
| 1 | DIM_CUSTOMER | Dimension | Customer master - all account attributes |
| 2 | DIM_PRODUCT | Dimension | Product catalog - SKUs, pricing, families |
| 3 | DIM_TIME | Dimension | Calendar - dates, fiscal periods, flags |
| 4 | DIM_ARR_CLASSIFICATION | Dimension | Movement type lookup - standardized categories |
| 5 | FACT_CONTRACT | Fact | Signed agreements - lifecycle tracking |
| 6 | FACT_CONTRACT_LINE | Fact | Line items - product/pricing detail per contract |
| 7 | FACT_SUBSCRIPTION | Fact | Active services - MRR/ARR delivery tracking |
| 8 | FACT_ARR_MONTHLY_SNAPSHOT | Fact | Point-in-time ARR - monthly customer-product state |
| 9 | FACT_ARR_MOVEMENT | Fact | ARR changes - classified deltas (waterfall source) |
| 10 | FACT_ARR_ADJUSTMENT | Fact | Manual adjustments - FX, credits, corrections |
| 11 | FACT_ARR_METRICS | Fact | Pre-aggregated KPIs - monthly executive metrics |
| 12 | FACT_ARR_FINAL_METRICS | Fact | Strategic rollup - quarterly/annual board metrics |

---

## Data Flow

```
Customer signs → CONTRACT → has LINE ITEMS (per product)
                                    ↓
                            SUBSCRIPTION activated
                                    ↓
                     Monthly SNAPSHOT captures ARR state
                                    ↓
                    MOVEMENT computed (delta vs prior month)
                                    ↓
              Pre-aggregated → ARR METRICS (monthly)
                                    ↓
                        Rolled up → FINAL METRICS (quarterly/annual)

                    ADJUSTMENTS applied independently
                    (FX, credits, corrections)
```
