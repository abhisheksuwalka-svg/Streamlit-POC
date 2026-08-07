# ARR Dashboard 2.0 — Project Documentation

**Author:** Abhishek Suwalka

## What We Built

A production-grade **Streamlit dashboard** that replaces Power BI for Annual Recurring Revenue (ARR) analytics. The solution connects live to Snowflake, provides 6 interactive tabs, an AI chatbot, and a full semantic data model — all deployable both locally and natively inside Snowflake (SiS).

---

## Project Timeline & Steps

### Step 1: Requirements Gathering

**Client requested:**
- A Power BI replacement using Streamlit
- Professional enterprise styling (white background, dark headers, green titles, blue/orange charts)
- Specific visuals: KPI cards, line charts, combo charts, matrix tables
- Specific slicers: Year, Month, ARR Type, Sales Rep, Region, DOS
- An AI chatbot for natural language data exploration
- Star schema data model with realistic sample data

---

### Step 2: Data Model Design (Star Schema)

We designed a **12-table star schema** following data warehouse best practices:

**Dimensions (4 tables):**

| Table | Purpose | Rows |
|-------|---------|------|
| DIM_CUSTOMER | Customer master — accounts, segments, regions | 20 |
| DIM_PRODUCT | Product catalog — SKUs, families, tiers, pricing | 8 |
| DIM_TIME | Calendar — dates, months, quarters, fiscal periods | 29 |
| DIM_ARR_CLASSIFICATION | Movement type lookup — New, Expansion, Churn, etc. | 6 |

**Facts (8 tables):**

| Table | Purpose | Rows |
|-------|---------|------|
| FACT_CONTRACT | Signed agreements with TCV/ACV | 30 |
| FACT_CONTRACT_LINE | Product-level line items per contract | 35 |
| FACT_SUBSCRIPTION | Active services with MRR/ARR | 35 |
| FACT_ARR_MONTHLY_SNAPSHOT | Point-in-time ARR per customer-product (month end) | 27 |
| FACT_ARR_MOVEMENT | Classified month-over-month ARR changes | 26 |
| FACT_ARR_ADJUSTMENT | Manual corrections, FX, credits | 6 |
| FACT_ARR_METRICS | Pre-aggregated monthly KPIs (executive layer) | 14 |
| FACT_ARR_FINAL_METRICS | Quarterly/annual strategic rollups | 6 |

**Relationships:** 16 foreign keys connecting all tables in a proper star schema.

---

### Step 3: Snowflake Deployment

**Database:** `ARR_WAREHOUSE`
**Schema:** `ARR_ANALYTICS`
**Warehouse:** `AI_WH`
**Role:** `SYSADMIN`

Executed in sequence:
1. `001_create_schema.sql` — Created all 12 tables with PKs, FKs, comments
2. `002_insert_sample_data.sql` — Populated with realistic SaaS ARR data (Feb 2025 – Mar 2026)
3. `003_create_views.sql` — Created 7 analytical views
4. `004_semantic_layer.sql` — Created 5 semantic views for BI tools

---

### Step 4: Analytical Views (7 views)

| View | Purpose | Used In |
|------|---------|---------|
| V_ARR_WATERFALL | Monthly ARR bridge (begin → movements → end) | Tab 1: Summary |
| V_ARR_BY_CUSTOMER | Current ARR per customer with attributes | Tab 2, 3 |
| V_ARR_MOVEMENT_DETAIL | Enriched movements with customer/product names | Tab 2, 3 |
| V_RETENTION_RATES | GRR/NRR with 3-month rolling averages | Tab 4 |
| V_ARR_BY_PRODUCT | ARR by product family and tier | Tab 2 |
| V_ARR_COHORT | Customer cohort retention analysis | Future use |
| V_SUBSCRIPTION_HEALTH | Renewal risk pipeline (days to renewal) | Tab 4 |

---

### Step 5: Streamlit Dashboard Development

**6 Tabs built:**

#### Tab 1: ARR Summary & Trends
- 5 KPI cards (Refresh Date, Ending ARR, Net New, GRR, NRR)
- Line chart: Ending ARR over time
- Line chart: GRR & NRR retention trends
- Combo chart: Stacked bars (Churn, Expansion, New Logo, FX) + Net ARR line
- Waterfall table: Monthly beginning → movements → ending

#### Tab 2: ARR Breakdown
- Donut chart: ARR by movement type
- Horizontal bars: ARR by Region, ARR by Segment
- Stacked bars: Monthly ARR by Growth/Contraction/Adjustment
- Product table: ARR by product family and tier

#### Tab 3: Sales Rep Performance
- Ranked bar: Current ARR by Account Owner
- Bar chart: Customer count per rep
- Movement attribution table: Growth vs Contraction by rep
- Customer portfolio detail table

#### Tab 4: Retention & Churn
- 4 KPI cards (Avg GRR, Avg NRR, Total Churn, Churned Logos)
- Retention trend with 3-month rolling average (smoothed lines)
- Monthly churn bar chart
- Renewal risk pipeline table (Critical/Approaching/Upcoming/Healthy)
- Quarterly strategic metrics table

#### Tab 5: AI Assistant
- Chat interface with conversation history
- Powered by Snowflake Cortex (llama3.1-70b) in SiS
- Falls back to local rule-based engine for common questions
- Answers: Ending ARR, retention, churn, top customers, regions, summaries
- Suggested question buttons for quick exploration

#### Tab 6: Data Catalog
- KPI cards: Tables count, Views count, Total Rows, Total Columns
- Tables inventory with row counts and descriptions
- Views inventory
- PK/FK constraints list
- Interactive explorer: Select any table/view → see columns + sample data
- Relationship map: All 16 FK connections

---

### Step 6: Enterprise Styling

| Element | Style |
|---------|-------|
| Page background | White (#FFFFFF) |
| Slicer headers | Black (#1A1A1A) with white text |
| Visual titles | Dark green (#1B5E20) |
| Primary charts | Blue (#2E5FA1) |
| Secondary charts | Orange (#E87722) |
| Net ARR line | Dark blue (#1B3A5C) |
| Positive values | Green (#4CAF50) |
| Negative values / Churn | Red (#D32F2F) |
| FX / Neutral | Grey (#546E7A) |

---

### Step 7: Two Deployment Versions

#### Local Version (`app.py`)
- Uses `snowflake-connector-python`
- Reads credentials from `~/.snowflake/connections.toml`
- Run with: `streamlit run app.py`
- Access at: `http://localhost:8501`

#### Streamlit in Snowflake Version (`streamlit_app.py`)
- Uses `snowflake.snowpark.context.get_active_session()` — no credentials
- Uses `snowflake.cortex.Complete()` for AI chatbot natively
- Deploy via Snowsight UI or `snow streamlit deploy`
- Access inside Snowsight — no local setup needed

---

### Step 8: GitHub Repository

**Repo:** https://github.com/abhisheksuwalka-svg/Streamlit-POC
**Branch:** `develop`

```
Streamlit-POC/
├── app.py                  # Local version
├── streamlit_app.py        # SiS version (deploy to Snowflake)
├── environment.yml         # SiS package dependencies
├── requirements.txt        # Local dependencies
├── .streamlit/config.toml  # Local Streamlit theme
├── .gitignore
├── SETUP.md                # How to set up and run
├── ABOUT.md                # What the dashboard does
└── sql/
    ├── 001_create_schema.sql
    ├── 002_insert_sample_data.sql
    ├── 003_create_views.sql
    ├── 004_semantic_layer.sql
    └── erd.md
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    USER (Browser)                         │
└──────────────────────────┬──────────────────────────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
    ┌─────────▼──────────┐   ┌─────────▼──────────┐
    │  Local Streamlit    │   │  Streamlit in       │
    │  (localhost:8501)   │   │  Snowflake (SiS)    │
    │  app.py             │   │  streamlit_app.py   │
    └─────────┬──────────┘   └─────────┬──────────┘
              │                         │
              │  snowflake-connector    │  snowpark session
              │                         │
    ┌─────────▼─────────────────────────▼──────────┐
    │              SNOWFLAKE                         │
    │  ┌─────────────────────────────────────────┐  │
    │  │  ARR_WAREHOUSE.ARR_ANALYTICS            │  │
    │  │                                         │  │
    │  │  Dimensions: Customer, Product, Time,   │  │
    │  │              ARR Classification         │  │
    │  │                                         │  │
    │  │  Facts: Contract, Contract Line,        │  │
    │  │         Subscription, Snapshot,         │  │
    │  │         Movement, Adjustment,           │  │
    │  │         Metrics, Final Metrics          │  │
    │  │                                         │  │
    │  │  Views: Waterfall, By Customer,         │  │
    │  │         By Product, Movements,          │  │
    │  │         Retention, Cohort, Health        │  │
    │  └─────────────────────────────────────────┘  │
    │                                               │
    │  ┌─────────────────────────────────────────┐  │
    │  │  Snowflake Cortex (AI)                  │  │
    │  │  llama3.1-70b for chatbot               │  │
    │  └─────────────────────────────────────────┘  │
    └───────────────────────────────────────────────┘
```

---

## Key Decisions Made

| Decision | Rationale |
|----------|-----------|
| Star schema (not flat table) | Proper dimensional modeling for flexible analytics |
| Pre-aggregated metrics table | Eliminates recomputation, fast dashboard loads |
| Views for analytics | Denormalized for easy consumption, source tables for integrity |
| Snowflake Cortex for AI | Native to Snowflake, no external API keys needed in SiS |
| Two app versions | Local for development, SiS for production deployment |
| Single database | Self-contained, no external dependencies |
| Plotly for charts | Interactive, professional, works in both local and SiS |

---

## How to Hand Off / Demo

1. **Quick demo:** Open http://localhost:8501 (local) or Snowsight (SiS)
2. **Show Tab 1** — Executive summary with KPIs and trends
3. **Use slicers** — Filter by Region = EMEA, show how all visuals update
4. **Show Tab 5** — Ask the AI: "Give me an ARR summary"
5. **Show Tab 6** — Data Catalog proves everything is live from Snowflake
6. **Compare to Power BI** — Live data, no refresh delays, AI chatbot, self-service

---

## What's Next (If Needed)

- Connect to real production ARR tables (replace sample data)
- Add row-level security (RLS) by role/region
- Add email alerts for churn risk
- Deploy to SiS for team-wide access
- Add more pages as client requests them
