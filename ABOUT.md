# What the ARR Dashboard Does

**Author:** Abhishek Suwalka

## Overview

The ARR Dashboard 2.0 is a **Power BI replacement** built on Streamlit and Snowflake. It provides real-time Annual Recurring Revenue analytics through an interactive, self-service interface that connects directly to live Snowflake tables — no data exports, no stale CSVs, no manual refreshes.

---

## Dashboard Tabs

### 1. ARR Summary & Trends

The executive view. Shows the complete ARR story at a glance:

- **KPI Cards:** Ending ARR, Net New ARR, Gross Retention Rate, Net Retention Rate
- **Ending ARR Line Chart:** Cumulative ARR growth over time
- **Retention Trends:** GRR and NRR plotted monthly
- **Combo Chart:** Stacked bars (Churn, Expansion, New Logo, FX) with Net ARR line overlay
- **Waterfall Table:** Monthly beginning → movements → ending ARR breakdown

### 2. ARR Breakdown

Dimensional analysis of where revenue comes from:

- **Donut Chart:** ARR by movement type (New Business, Expansion, Churn, etc.)
- **Horizontal Bars:** Current ARR by Region and Segment
- **Stacked Bars:** Monthly ARR split by Growth / Contraction / Adjustment
- **Product Table:** ARR by product family and tier

### 3. Sales Rep Performance

Account owner attribution and portfolio analysis:

- **Ranked Bar Chart:** Current ARR by Account Owner
- **Customer Count:** Portfolio size per rep
- **Movement Attribution Table:** Growth vs Contraction by rep
- **Customer Portfolio:** Full detail table with ARR, tenure, products

### 4. Retention & Churn

Deep dive into revenue retention health:

- **KPI Cards:** Avg GRR, Avg NRR, Total Churn, Churned Logos
- **Retention Trend with 3-Month Rolling Average:** Smoothed GRR/NRR lines
- **Monthly Churn Bars:** Absolute churn value per month
- **Renewal Risk Pipeline:** Subscriptions grouped by days-to-renewal risk tier
- **Quarterly Strategic Metrics:** Board-level growth, retention, and customer counts

### 5. AI Assistant

Natural language Q&A over your ARR data:

- Ask questions like: "What is our current ending ARR?" or "Who are the top 5 customers?"
- Powered by **Snowflake Cortex** (primary), **OpenAI** (fallback), or **local rule-based** engine
- Context built from live filtered data — answers respect your slicer selections
- Suggested questions provided for quick exploration

### 6. Data Catalog

Full visibility into the underlying data model:

- **Inventory:** Count of tables, views, total rows, total columns
- **Table & View Lists:** With row counts and descriptions
- **PK/FK Constraints:** All relationships documented
- **Interactive Explorer:** Select any table or view → see columns + sample data
- **ER Diagram:** Mermaid-rendered entity relationship chart
- **Relationship Map:** All 16 foreign key connections listed

---

## Data Model

The dashboard is powered by a **star schema** in Snowflake:

| Layer | Tables | Purpose |
|-------|--------|---------|
| Dimensions | 4 | Customer, Product, Time, ARR Classification |
| Facts | 8 | Contract, Contract Line, Subscription, Monthly Snapshot, Movement, Adjustment, Metrics, Final Metrics |
| Views | 7 | Waterfall, By Customer, By Product, Movements, Retention, Cohort, Subscription Health |
| Semantic | 5 | Denormalized views with display-friendly names for BI tools |

**Location:** `ARR_WAREHOUSE.ARR_ANALYTICS`

---

## Why This Replaces Power BI

| Power BI | This Dashboard |
|----------|---------------|
| Scheduled refresh (stale data) | Live Snowflake queries (always current) |
| Desktop license required | Browser — works on any device |
| DAX complexity | Python/SQL — easier to maintain |
| Limited interactivity | Full Streamlit widgets + AI chatbot |
| Separate semantic model | Semantic layer lives in Snowflake (single source of truth) |
| No natural language queries | Built-in AI assistant for data exploration |
| Expensive Pro/Premium licensing | Open source (Streamlit + Snowflake) |

---

## Interactive Slicers

All tabs are filtered by the sidebar slicers:

- **Year** — Filter by calendar year
- **Quarter** — Filter by Q1/Q2/Q3/Q4
- **Region** — North America, EMEA, APAC, LATAM
- **Segment** — Enterprise, Mid-Market, SMB
- **Movement Type** — New Business, Expansion, Contraction, Churn, Resurrection, FX
- **Account Owner** — Filter by sales rep

All default to "All" for full dataset visibility.
