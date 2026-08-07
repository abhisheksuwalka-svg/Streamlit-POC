# ARR Dashboard 2.0

**Replacing Power BI with real-time Snowflake analytics.**

A Streamlit dashboard for Annual Recurring Revenue (ARR) analytics that queries Snowflake
live — no scheduled refresh, no data extracts, plus a built-in AI assistant for
natural-language questions.

**Author:** Abhishek Suwalka

---

## What's inside

- **6 interactive tabs** — Summary & Trends, ARR Breakdown, Sales Rep Performance,
  Retention & Churn, AI Assistant, Data Catalog
- **12-table star schema** in Snowflake with 16 foreign-key relationships
- **12 views** — 7 analytical + 5 BI-ready semantic
- **14 months of data** (Feb 2025 – Mar 2026), ARR growing $2.38M → $2.95M
- **AI assistant** powered by Snowflake Cortex — ask questions in plain English
- **3 deployment modes** — local, Streamlit in Snowflake, or containerised on SPCS

---

## Before you start

You need a **Snowflake account login** with access to `ARR_WAREHOUSE.ARR_ANALYTICS`.

If you get `Object does not exist or not authorized`, you don't have access yet — jump to
[Getting access](#getting-access).

---

# Part 1 — Access the Dashboard

Pick one of three routes.

| Route | Time | Need Python? | Choose this if… |
|---|---|---|---|
| **A** — Open the live URL | 1 min | No | You just want to look at it |
| **B** — Run on your laptop | 10 min | Yes | You want to change the code |
| **C** — Your own Snowsight copy | 5 min | No | You want to share with your team |

---

## Route A — Open the live URL

The dashboard is already running. Nothing to install.

**Step 1.** Get the URL. Ask the project owner, or run this in Snowsight:

```sql
SHOW ENDPOINTS IN SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE;
```

Copy the value in the `ingress_url` column.

**Step 2.** Paste it into your browser, prefixed with `https://`

**Step 3.** Log in with your Snowflake credentials when prompted.

That's it.

> **Page won't load?** The service is probably suspended to save credits. Ask the owner to
> resume it, or see [Start / stop the service](#start-and-stop-the-service).

---

## Route B — Run it on your laptop

Use this if you plan to make changes.

**Requirements:** Python 3.9 or newer, and Git.

**Step 1.** Clone the repository.

```bash
git clone https://github.com/abhisheksuwalka-svg/Streamlit-POC.git
cd Streamlit-POC
git checkout develop
```

**Step 2.** Create a virtual environment.

```bash
python3 -m venv .venv
source .venv/bin/activate          # macOS / Linux
# .venv\Scripts\activate           # Windows
```

**Step 3.** Install dependencies.

```bash
pip install -r requirements.txt
```

**Step 4.** Set up your Snowflake connection.

Create the file `~/.snowflake/connections.toml` — note this lives **outside** the repo and
must never be committed:

```toml
[SPCS]
account = "your_account_locator"
user = "your_user"
authenticator = "externalbrowser"
```

**Step 5.** Set your role. **Don't skip this — it's the most common failure.**

Open `app.py` and go to **line 95**:

```python
role="SYSADMIN",
```

If you don't have `SYSADMIN`, change it to a role you actually hold. Otherwise the app
will fail on startup with a permissions error.

**Step 6.** Run it.

```bash
streamlit run app.py
```

Opens at **http://localhost:8501**

> You do **not** need to run the SQL scripts in `sql/`. The data already exists in
> Snowflake. Those scripts are only for building a fresh environment from scratch.

---

## Route C — Deploy your own Snowsight copy

Runs inside Snowflake. No local setup, no credentials, no role to edit.

**Step 1.** In Snowsight, go to **Projects → Streamlit → + Streamlit App**

**Step 2.** Set:
- **App location:** `ARR_WAREHOUSE` / `ARR_ANALYTICS`
- **Warehouse:** `AI_WH`

**Step 3.** Delete the sample code, then paste the full contents of **`streamlit_app.py`**

> Use `streamlit_app.py`, **not** `app.py`. The local version expects a credentials file
> that doesn't exist inside Snowflake.

**Step 4.** Open the **Packages** dropdown and add:

```
plotly
pandas
snowflake-snowpark-python
```

**Step 5.** Click **Run**.

This route is the best option for business users — there's no container to suspend, so it
can't go dark unexpectedly.

---

# Part 2 — Make Changes

## Step 1 — Know which file to edit

There are **three** copies of the dashboard, one per deployment mode:

| File | Runs where | Connects via |
|---|---|---|
| `app.py` | Your laptop | `connections.toml` |
| `streamlit_app.py` | Streamlit in Snowflake | Active session |
| `spcs_app.py` | SPCS container | OAuth token |

**Editing one does not change the others.** If a fix should reach everyone, apply the same
edit to all three.

## Step 2 — Create a branch

```bash
git checkout develop
git pull
git checkout -b feature/your-change
```

Set your Git identity first if you haven't, so commits show your name and not your
computer's hostname:

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@company.com"
```

## Step 3 — Make your edit

| I want to… | Edit this |
|---|---|
| Add or change a chart | The relevant `with tab1:` … `with tab6:` block |
| Change how a metric is calculated | `sql/003_create_views.sql` — **not** the Python |
| Point at real production data | The view definitions in `sql/003_create_views.sql` |
| Change colours | `.streamlit/config.toml`, plus the colour constants at the top of the app file |
| Add a new tab | The `st.tabs([...])` list, then add a matching `with tabN:` block |

**Why metrics belong in SQL:** the views are the single source of truth. Change a metric
there and it updates all three dashboards *and* any future BI tool. Change it in Python and
you've created a discrepancy.

## Step 4 — Test locally

```bash
streamlit run app.py
```

Click through every tab you touched. Check the **Data Catalog** tab last — it confirms the
Snowflake connection is healthy.

## Step 5 — Commit and push

```bash
git add -A
git commit -m "Describe what changed and why"
git push -u origin feature/your-change
```

## Step 6 — Open a pull request

On GitHub, open a PR from your branch into **`develop`**.

## Step 7 — Redeploy (only if you changed the deployed versions)

**If you changed `streamlit_app.py`** — paste the new code into the Snowsight editor, or:

```bash
snow streamlit deploy --replace --connection SPCS
```

**If you changed `spcs_app.py`** — the container needs rebuilding:

```bash
export SF_REGISTRY="<your-account>-spcs.registry.snowflakecomputing.com"
./deploy.sh
```

then tell the service to pick up the new image:

```sql
USE ROLE ACCOUNTADMIN;
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE
    FROM @ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_STAGE
    SPECIFICATION_FILE = 'spec.yaml';
```

---

# Getting Access

If you can't query the data, an admin needs to run this once. Replace `THEIR_USERNAME`.

```sql
USE ROLE USERADMIN;
CREATE ROLE IF NOT EXISTS ARR_DASHBOARD_VIEWER;

USE ROLE SYSADMIN;
GRANT USAGE  ON DATABASE ARR_WAREHOUSE                           TO ROLE ARR_DASHBOARD_VIEWER;
GRANT USAGE  ON SCHEMA   ARR_WAREHOUSE.ARR_ANALYTICS             TO ROLE ARR_DASHBOARD_VIEWER;
GRANT SELECT ON ALL TABLES IN SCHEMA ARR_WAREHOUSE.ARR_ANALYTICS TO ROLE ARR_DASHBOARD_VIEWER;
GRANT SELECT ON ALL VIEWS  IN SCHEMA ARR_WAREHOUSE.ARR_ANALYTICS TO ROLE ARR_DASHBOARD_VIEWER;
GRANT USAGE  ON WAREHOUSE AI_WH                                  TO ROLE ARR_DASHBOARD_VIEWER;

-- Needed for the AI Assistant tab
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ARR_DASHBOARD_VIEWER;

-- Needed only for Route A (the live URL)
USE ROLE ACCOUNTADMIN;
GRANT USAGE ON SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE
    TO ROLE ARR_DASHBOARD_VIEWER;

USE ROLE USERADMIN;
GRANT ROLE ARR_DASHBOARD_VIEWER TO USER THEIR_USERNAME;
```

Anyone who already holds `ACCOUNTADMIN` or `SYSADMIN` has access and needs none of this.

---

# Start and Stop the Service

**A running SPCS service stops its compute pool from auto-suspending** — it bills
continuously regardless of the auto-suspend setting. Suspend both when idle.

```sql
USE ROLE ACCOUNTADMIN;

-- Stop billing
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE SUSPEND;
ALTER COMPUTE POOL STREAMLIT_CPU_POOL SUSPEND;

-- Bring it back — pool first, then service
ALTER COMPUTE POOL STREAMLIT_CPU_POOL RESUME;
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE RESUME;

-- Check state
SHOW SERVICES IN SCHEMA ARR_WAREHOUSE.ARR_ANALYTICS;
```

Allow a minute or two after resuming before the endpoint responds.

---

# Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Object does not exist or not authorized` | No grants on the schema | Run the [grant block](#getting-access) |
| `Role 'SYSADMIN' is not granted to this user` | Hardcoded role | Change `app.py` line 95 |
| Live URL won't load | Service suspended | [Resume it](#start-and-stop-the-service) |
| First query hangs a few seconds | Warehouse was asleep | Normal — it's waking up |
| AI Assistant tab errors | Missing Cortex privilege | `GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER` |
| Retention tab shows 100% every month | Sample-data artifact | Known limitation, not a bug |
| `Port 8501 is already in use` | Another Streamlit running | `lsof -ti:8501 \| xargs kill -9` |
| `docker: command not found` | Docker Desktop not running | Start Docker Desktop |

---

# Repository Contents

```
Streamlit-POC/
├── app.py                      Local dashboard
├── streamlit_app.py            Streamlit in Snowflake version
├── spcs_app.py                 SPCS container version
│
├── sql/
│   ├── 001_create_schema.sql   12 tables, keys, comments
│   ├── 002_insert_sample_data.sql
│   ├── 003_create_views.sql    7 analytical views
│   ├── 004_semantic_layer.sql  5 semantic views
│   └── erd.md                  ER diagram
│
├── Dockerfile                  SPCS container image
├── spec.yaml                   SPCS service spec
├── deploy.sh                   Build, tag, push
├── requirements.txt            Local dependencies
├── environment.yml             Snowsight packages
└── .streamlit/config.toml      Theme
```

---

# Documentation

| Document | Read it for |
|---|---|
| **README.md** | You're here — access and change instructions |
| [ACCESS.md](ACCESS.md) | Deeper detail on permissions and contribution |
| [ABOUT.md](ABOUT.md) | What each tab shows, and why |
| [SETUP.md](SETUP.md) | Building a fresh environment from scratch |
| [IMPLEMENTATION_REPORT.md](IMPLEMENTATION_REPORT.md) | Formal write-up — scope, architecture, decisions |
| [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) | Technical walkthrough |
| [SPCS_DEPLOYMENT.md](SPCS_DEPLOYMENT.md) | Container build and deployment record |
| [sql/erd.md](sql/erd.md) | Entity-relationship diagram |

---

# Known Limitations

- **Sample data.** 20 customers, 14 months, synthetic. The dashboard reads *views*, so
  repointing at production ARR data is a configuration change, not a rebuild.
- **Retention figures are flat.** GRR reads 100% for 13 of 14 months — a data generation
  artifact, not a calculation error.
- **Three app files to keep in sync.** A change to one doesn't propagate to the others.

---

*Built with Snowflake, Streamlit, Plotly, and Snowflake Cortex.*
