# ARR Dashboard 2.0 — Implementation Report

**Project:** Power BI to Streamlit on Snowflake Migration (Proof of Concept)
**Repository:** `https://github.com/abhisheksuwalka-svg/Streamlit-POC` (branch `develop`)
**Status:** Complete — deployed and operational
**Document purpose:** End-to-end record of scope, approach, implementation, and outcomes.

---

## 1. Executive Summary

We delivered a working replacement for an existing Power BI ARR (Annual Recurring Revenue) dashboard, rebuilt as a Streamlit application running natively on Snowflake.

The proof of concept demonstrates three things:

1. **Feature parity is achievable.** All originally specified visuals, filters, and metrics were reproduced without simplification.
2. **Live data replaces scheduled refresh.** The dashboard queries Snowflake directly, so figures are current at page load rather than as of the last import.
3. **Snowflake-native AI is available at no integration cost.** A natural-language assistant was added using Snowflake Cortex, requiring no external API keys or third-party services.

Alongside the dashboard we built a complete, self-contained ARR data model — 12 tables, 16 foreign-key relationships, 12 views, and a populated 14-month dataset — so the POC runs independently of any production system.

**Scale of delivery:** approximately 4,600 lines across 21 files — 2,230 lines of Python, 1,139 lines of SQL, 1,082 lines of documentation, and the remainder deployment configuration.

---

## 2. Business Objective and Scope

### The problem

The existing Power BI ARR dashboard had three limitations:

| Limitation | Business impact |
|---|---|
| Scheduled data refresh | Figures presented in meetings could be hours or days stale |
| Licensing per viewer | Cost scales with audience size |
| No conversational access | Every new question requires a developer or analyst |

### What was requested

The requirement was a like-for-like rebuild, explicitly specified rather than left to interpretation:

- **Star schema:** fact and dimension tables for ARR, date, sales representative, and ARR type
- **Six filters:** Year, Month, ARR Type, Sales Rep, Region, DOS — each defaulting to "All"
- **Five visuals:** KPI card, two line charts, a line-and-stacked-column combination chart, and a matrix
- **Nine or more calculated measures** covering ARR movement and retention
- **A defined enterprise colour theme**
- **An AI assistant** for natural-language questions against the data

A standing constraint applied throughout: *no simplification, and no unilateral design decisions.* Every element was built to specification, with confirmation sought before expanding scope.

### What was delivered beyond the original brief

Three additions were made at your request as the POC progressed:

- Expansion from one page to **six tabs**, covering breakdown, sales performance, retention, AI, and a data catalogue
- A **12-table semantic model** with sample data, replacing the initial 4-table sketch
- **Three deployment modes** — local, Streamlit in Snowflake, and Snowpark Container Services

---

## 3. Solution Architecture

```
                          ┌─────────────────┐
                          │  User (browser) │
                          └────────┬────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
┌───────▼────────┐      ┌──────────▼─────────┐    ┌───────────▼──────────┐
│ Local          │      │ Streamlit in       │    │ Snowpark Container   │
│ localhost:8501 │      │ Snowflake (SiS)    │    │ Services (SPCS)      │
│ app.py         │      │ streamlit_app.py   │    │ spcs_app.py + Docker │
└───────┬────────┘      └──────────┬─────────┘    └───────────┬──────────┘
        │                          │                          │
   connector.toml            Snowpark session          OAuth token file
        │                          │                          │
        └──────────────────────────┼──────────────────────────┘
                                   │
        ┌──────────────────────────▼──────────────────────────┐
        │                    SNOWFLAKE                         │
        │                                                      │
        │  ARR_WAREHOUSE.ARR_ANALYTICS                         │
        │  ├─ 4 dimension tables                               │
        │  ├─ 8 fact tables                                    │
        │  ├─ 7 analytical views                               │
        │  └─ 5 semantic views (BI-ready)                      │
        │                                                      │
        │  Snowflake Cortex — llama3.1-70b (AI assistant)      │
        │  Compute: AI_WH (queries), STREAMLIT_CPU_POOL (SPCS) │
        └──────────────────────────────────────────────────────┘
```

The application layer is interchangeable; the data layer is shared. All three deployment modes read the same tables and views, which means a change to the data model propagates everywhere without code duplication.

---

## 4. Implementation Phases

The work proceeded in ten phases. All commits landed in a single working session; phases are sequential rather than calendar-dated.

### Phase 1 — Requirements capture

Documented the full specification: table structures, filter behaviour, visual types, measure definitions, and the colour palette. Confirmed the specification before writing code, per the no-unilateral-decisions constraint.

### Phase 2 — Initial build and platform pivot

Built the dashboard first against the Power BI project-as-code format (PBIP/TMDL), then pivoted to Streamlit when you redirected the platform choice. The PBIP artefacts were removed.

### Phase 3 — Data model design

Designed a 12-table star schema following dimensional modelling practice.

**Dimensions (4):**

| Table | Purpose | Rows |
|---|---|---|
| `DIM_CUSTOMER` | Customer master — account, segment, region, owner | 20 |
| `DIM_PRODUCT` | Product catalogue — SKU, family, tier, list price | 8 |
| `DIM_TIME` | Calendar — date, month, quarter, fiscal period | 29 |
| `DIM_ARR_CLASSIFICATION` | Movement type lookup | 6 |

**Facts (8):**

| Table | Purpose | Rows |
|---|---|---|
| `FACT_CONTRACT` | Signed agreements with TCV and ACV | 30 |
| `FACT_CONTRACT_LINE` | Product-level line items | 35 |
| `FACT_SUBSCRIPTION` | Active services with MRR and ARR | 35 |
| `FACT_ARR_MONTHLY_SNAPSHOT` | Month-end ARR per customer-product | 27 |
| `FACT_ARR_MOVEMENT` | Classified month-over-month changes | 26 |
| `FACT_ARR_ADJUSTMENT` | Manual corrections, FX, credits | 6 |
| `FACT_ARR_METRICS` | Pre-aggregated monthly KPIs | 14 |
| `FACT_ARR_FINAL_METRICS` | Quarterly and annual rollups | 6 |

Sixteen foreign keys connect the schema. An entity-relationship diagram was produced in Mermaid format (`sql/erd.md`) alongside a written relationship map.

**Design rationale:** ARR movement is modelled explicitly as its own fact table rather than derived at query time. This means the classification of each change — New Business, Expansion, Contraction, Churn, Resurrection, FX Adjustment — is auditable and consistent across every visual, rather than being recalculated by each report.

### Phase 4 — Snowflake deployment

Deployed to `ARR_WAREHOUSE.ARR_ANALYTICS` using warehouse `AI_WH`, executing four scripts in sequence:

| Script | Contents |
|---|---|
| `001_create_schema.sql` | 12 tables with primary keys, foreign keys, column comments |
| `002_insert_sample_data.sql` | 14 months of realistic SaaS data (Feb 2025 – Mar 2026) |
| `003_create_views.sql` | 7 analytical views |
| `004_semantic_layer.sql` | 5 semantic views with measure definitions for BI tools |

Referential integrity was verified after load by running join queries across all foreign-key paths.

### Phase 5 — Analytical view layer

Seven views abstract query complexity away from the application:

| View | Purpose | Consumed by |
|---|---|---|
| `V_ARR_WATERFALL` | Monthly ARR bridge: beginning → movements → ending | Tab 1 |
| `V_ARR_BY_CUSTOMER` | Current ARR per customer with attributes | Tabs 2, 3 |
| `V_ARR_MOVEMENT_DETAIL` | Movements enriched with customer and product names | Tabs 2, 3 |
| `V_RETENTION_RATES` | GRR and NRR with 3-month rolling averages | Tab 4 |
| `V_ARR_BY_PRODUCT` | ARR by product family and tier | Tab 2 |
| `V_ARR_COHORT` | Cohort retention analysis | Reserved |
| `V_SUBSCRIPTION_HEALTH` | Renewal risk by days to renewal | Tab 4 |

Keeping business logic in views rather than application code means the same definitions are available to any future consumer — Power BI, Tableau, or direct SQL.

### Phase 6 — Dashboard development

Six tabs were built:

**Tab 1 — ARR Summary & Trends.** Five KPI cards (refresh date, ending ARR, net new ARR, GRR, NRR); ending-ARR trend line; GRR and NRR retention lines; combination chart with stacked movement bars and a net-ARR overlay line; monthly waterfall table.

**Tab 2 — ARR Breakdown.** Movement-type donut; horizontal bars by region and by segment; monthly stacked bars split by growth, contraction, and adjustment; product family and tier table.

**Tab 3 — Sales Rep Performance.** Ranked ARR by account owner; customer count per representative; movement attribution table separating growth from contraction; customer portfolio detail.

**Tab 4 — Retention & Churn.** Four KPI cards; retention trend with 3-month rolling smoothing; monthly churn bars; renewal-risk pipeline banded Critical / Approaching / Upcoming / Healthy; quarterly strategic metrics.

**Tab 5 — AI Assistant.** Chat interface with conversation history, backed by Snowflake Cortex (`llama3.1-70b`). Answers questions on ARR totals, retention, churn, top customers, and regional performance. Includes suggested-question shortcuts and a rule-based fallback for common queries.

**Tab 6 — Data Catalog.** Inventory of all tables and views with row and column counts; primary and foreign key listing; interactive explorer allowing selection of any object to inspect its columns and sample rows; full relationship map.

The Data Catalog tab serves a specific purpose in demonstrations: it proves the figures are being read live from Snowflake rather than from a static extract.

### Phase 7 — Enterprise styling

The specified palette was applied via injected CSS and Plotly templates:

| Element | Colour |
|---|---|
| Page background | White `#FFFFFF` |
| Filter headers | Black `#1A1A1A`, white text |
| Visual titles | Dark green `#1B5E20` |
| Primary series | Blue `#2E5FA1` |
| Secondary series | Orange `#E87722` |
| Net ARR line | Dark blue `#1B3A5C` |
| Positive values | Green `#4CAF50` |
| Negative values, churn | Red `#D32F2F` |
| FX, neutral | Grey `#546E7A` |

### Phase 8 — Version control

Initialised the repository, pushed to GitHub on the `develop` branch, and renamed the project from `CDK-POC` to `Streamlit-POC`. Authored two reader-facing documents: `SETUP.md` (installation and run instructions) and `ABOUT.md` (dashboard capabilities).

### Phase 9 — Containerisation and SPCS deployment

Evaluated Streamlit in Snowflake against Snowpark Container Services and implemented both.

Built a Docker image on `python:3.9-slim`, targeting `linux/amd64` as required by the SPCS x86_64 runtime. Created the supporting Snowflake objects — image repository, stage, and compute pool — then pushed the image and started the service.

| Component | Value |
|---|---|
| Image repository | `ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_REPO` |
| Specification stage | `ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_STAGE` |
| Service | `ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE` |
| Compute pool | `STREAMLIT_CPU_POOL` (CPU_X64_S, 1–2 nodes) |
| Container resources | 512 MB–1 GB memory, 0.5–1 CPU |
| Endpoint | Port 8501, public HTTPS, Snowflake login required |

The service reached READY status and served the dashboard successfully. A deployment script (`deploy.sh`) automates image build, tag, and push.

### Phase 10 — Security review and sanitisation

Audited the repository prior to external sharing and remediated the findings:

- Replaced the account locator and live service URL with `<ACCOUNT>` and `<SERVICE_ID>` placeholders across all documentation
- Parameterised `deploy.sh` through `SF_REGISTRY` and `SF_USER` environment variables, with a guard that halts execution if left unconfigured
- Replaced hardcoded registry authentication with Snow CLI OAuth (`snow spcs image-registry login`), removing the embedded username
- Hardened `.gitignore` against `connections.toml`, `.env*`, `secrets.toml`, `*.pem`, `*.p8`, `*.key`, and service-account files
- Added a security note to `SETUP.md` confirming the repository contains no credentials

Verification: a pattern scan across all tracked files for account identifiers, usernames, service IDs, and local filesystem paths returned zero matches.

---

## 5. Deployment Options — Comparison

Three modes were built. Each suits a different stage.

| | Local | Streamlit in Snowflake | SPCS |
|---|---|---|---|
| **File** | `app.py` | `streamlit_app.py` | `spcs_app.py` |
| **Authentication** | `connections.toml` | Active Snowpark session | OAuth token, injected |
| **Credentials to manage** | Yes | None | None |
| **Infrastructure** | Developer machine | Managed by Snowflake | Compute pool |
| **Container control** | n/a | None | Full |
| **Custom packages** | Unrestricted | Anaconda channel only | Unrestricted |
| **Compute cost** | None | Warehouse only | Warehouse + compute pool |
| **Best suited to** | Development | Internal business users | Custom dependencies, external access |

**Recommendation for production:** Streamlit in Snowflake. It removes credential handling entirely, requires no container lifecycle management, and incurs warehouse cost only. SPCS is the right answer where a package outside the Anaconda channel is required, or where the dashboard must be reachable outside Snowsight.

---

## 6. Technical Challenges and Resolutions

Eleven issues were encountered and resolved. The substantive ones:

| Issue | Root cause | Resolution |
|---|---|---|
| `TypeError` on aggregation | Residual dead code — an `.agg()` call over an empty comprehension | Removed the block; retained the explicit aggregation loop |
| Blank tab pages | `include_groups=False` and DataFrame `.map()` require pandas 2.1+; runtime was Python 3.9 | Rewrote using explicit `groupby` iteration and `.applymap()` |
| Insufficient privileges on DDL | Session defaulted to role `PUBLIC` | `SYSADMIN` for schema objects; `ACCOUNTADMIN` for image repository and service |
| `No current database` on schema creation | Database not yet created | Created `ARR_WAREHOUSE` first, then set context |
| Column count mismatch on insert | Implicit column list did not account for a `CREATED_AT` default | Specified explicit column names |
| Image rejected by SPCS | Image built for arm64 on Apple Silicon | Rebuilt with `--platform linux/amd64` |
| Push rejected after repository rename | Remote history diverged from local | Force-pushed clean history to the renamed repository |

**Scope note:** during development, additional tabs were built before confirmation. Given the standing "no unilateral design decisions" constraint, these were removed on request, then reinstated once it was established that the blank-page fault was the pandas incompatibility rather than the tabs themselves.

---

## 7. Cost and Operational Considerations

### One finding worth flagging

**A running SPCS service prevents its compute pool from auto-suspending.** The pool was configured with `auto_suspend_secs = 3600`, but that timer only starts once no service is running on it. While `ARR_DASHBOARD_SERVICE` stays up, the pool bills continuously — the auto-suspend setting alone does not protect against idle cost.

To stop consumption, the service must be suspended explicitly:

```sql
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE SUSPEND;
ALTER COMPUTE POOL STREAMLIT_CPU_POOL SUSPEND;

-- To resume
ALTER COMPUTE POOL STREAMLIT_CPU_POOL RESUME;
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE RESUME;
```

This is the strongest practical argument for Streamlit in Snowflake in production: there is no pool to leave running.

### Cost profile by mode

| Mode | Cost drivers |
|---|---|
| Local | Warehouse credits during query execution only |
| Streamlit in Snowflake | Warehouse credits during query execution only |
| SPCS | Warehouse credits, plus compute pool credits for the entire time the service is up |

Query results are cached in the application for five minutes, which limits warehouse wake-ups during interactive use.

---

## 8. Deliverables

| File | Lines | Contents |
|---|---|---|
`app.py` | 822 | Local dashboard, all six tabs |
`spcs_app.py` | 724 | Container variant, OAuth authentication |
`streamlit_app.py` | 684 | Streamlit in Snowflake variant |
`sql/002_insert_sample_data.sql` | 343 | 14 months of sample data |
`sql/001_create_schema.sql` | 341 | 12 tables, keys, comments |
`sql/003_create_views.sql` | 229 | 7 analytical views |
`sql/004_semantic_layer.sql` | 226 | 5 semantic views |
`sql/erd.md` | 218 | Mermaid ER diagram, relationship map |
`SPCS_DEPLOYMENT.md` | 385 | Container build and deployment record |
`PROJECT_DOCUMENTATION.md` | 261 | Technical walkthrough |
`ABOUT.md` | 111 | Dashboard capability overview |
`SETUP.md` | 107 | Installation and run instructions |
`deploy.sh` | 82 | Automated build, tag, push |
`Dockerfile`, `spec.yaml`, `environment.yml`, `requirements*.txt`, `.streamlit/config.toml` | ~70 | Build and runtime configuration |

---

## 9. Current Status

| Item | State |
|---|---|
| Data model | Deployed, populated, integrity verified |
| Views | 7 analytical + 5 semantic, operational |
| Dashboard — local | Working |
| Dashboard — Streamlit in Snowflake | Code complete, ready to deploy |
| Dashboard — SPCS | Deployed, reached READY |
| AI assistant | Working on Cortex `llama3.1-70b` |
| Repository | Pushed to `develop`, sanitised for sharing |
| Documentation | Five documents, this report included |

---

## 10. Recommended Next Steps

**To move to production:**

1. Repoint the views at production ARR tables, replacing sample data. Application code requires no change — it reads views, not tables.
2. Deploy to Streamlit in Snowflake for business-user access.
3. Suspend the SPCS service and compute pool to halt POC costs.

**Enhancements to consider:**

- Row-level security by region or sales territory, so representatives see only their own accounts
- Scheduled alerting on churn-risk thresholds
- Extension of the semantic layer for self-service Cortex Analyst queries
- Historical trend depth beyond the current 14 months once real data is connected

---

## Appendix — Demonstration Sequence

A suggested ten-minute walkthrough:

1. **Tab 1** — Open on the executive summary. Note that KPI figures are queried live.
2. **Filters** — Set Region to EMEA. All visuals update together.
3. **Tab 4** — Show the retention trend and the renewal-risk pipeline.
4. **Tab 5** — Ask the assistant: *"Give me an ARR summary."* Then a follow-up in plain language.
5. **Tab 6** — Open the Data Catalog. Select a table and show its live row count and sample data, evidencing the direct Snowflake connection.
6. **Close on the comparison** — live figures rather than scheduled refresh, conversational access, and no per-viewer licence.
