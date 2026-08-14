# Access & Contribution Guide

**Author:** Abhishek Suwalka

How to view the ARR Dashboard, and how to make changes to it.

---

## Part 1 — Viewing the Dashboard

There are three ways in. Pick based on what you need.

| | Effort | Needs Python? | Best for |
|---|---|---|---|
| **A. Live URL** | None | No | Just looking at it |
| **B. Run locally** | ~10 min | Yes | Making changes |
| **C. Your own Snowsight copy** | ~5 min | No | Sharing with your own team |

---

### Option A — Open the live URL

The dashboard is already running on Snowpark Container Services. Nothing to install.

1. Open **https://bjd4a65p-se58322-spcs.snowflakecomputing.app**
   If that link has changed, get the current one with:
   ```sql
   SHOW ENDPOINTS IN SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE;
   ```
   and open the `ingress_url` in a browser.
2. Log in with your Snowflake credentials when prompted.

**Requirements:** a Snowflake account login, plus `USAGE` on the service (see
[Granting Access](#granting-access-to-others) below).

If the page does not load, the service may be suspended to save credits. Ask the owner
to resume it — see [Starting and Stopping](#starting-and-stopping-the-service).

---

### Option B — Run it locally

Use this if you want to change the code.

**Prerequisites:** Python 3.9+, Git, and a Snowflake account with access to
`ARR_WAREHOUSE.ARR_ANALYTICS`.

```bash
# 1. Clone
git clone https://github.com/abhisheksuwalka-svg/Streamlit-POC.git
cd Streamlit-POC
git checkout develop

# 2. Virtual environment
python3 -m venv .venv
source .venv/bin/activate          # macOS / Linux
# .venv\Scripts\activate           # Windows

# 3. Dependencies
pip install -r requirements.txt
```

**4. Configure your connection.** Create or edit `~/.snowflake/connections.toml` — this
lives outside the repo and must never be committed:

```toml
[SPCS]
account = "your_account_locator"
user = "your_user"
authenticator = "externalbrowser"
```

**5. Set your role.** This step is easy to miss. `app.py` line 95 hardcodes the role:

```python
role="SYSADMIN",
```

If you do not have `SYSADMIN`, change this to a role you *do* hold and which has been
granted access to the schema. Otherwise you will get a permissions error on startup.

```bash
# 6. Run
streamlit run app.py
```

Opens at **http://localhost:8501**.

> The data already exists in Snowflake. You do **not** need to run the SQL scripts in
> `sql/` unless you are building a fresh environment from scratch.

---

### Option C — Deploy your own Snowsight copy

Runs inside Snowflake. No local setup, no credentials to manage.

1. In Snowsight, go to **Projects → Streamlit → + Streamlit App**
2. Set the app location to `ARR_WAREHOUSE.ARR_ANALYTICS` and warehouse to `AI_WH`
3. Paste the contents of `streamlit_app.py` (**not** `app.py`)
4. Under **Packages**, add: `plotly`, `pandas`, `snowflake-snowpark-python`
5. Run

`streamlit_app.py` authenticates through the active Snowsight session, so there is no
connection file and no hardcoded role to change.

---

## Granting Access to Others

Run this once as an admin to let a colleague use the dashboard. Replace
`THEIR_USERNAME`.

```sql
-- Create a viewer role (requires USERADMIN or higher)
USE ROLE USERADMIN;
CREATE ROLE IF NOT EXISTS ARR_DASHBOARD_VIEWER;

-- Grant read access to the data
USE ROLE SYSADMIN;
GRANT USAGE  ON DATABASE ARR_WAREHOUSE                      TO ROLE ARR_DASHBOARD_VIEWER;
GRANT USAGE  ON SCHEMA   ARR_WAREHOUSE.ARR_ANALYTICS        TO ROLE ARR_DASHBOARD_VIEWER;
GRANT SELECT ON ALL TABLES IN SCHEMA ARR_WAREHOUSE.ARR_ANALYTICS TO ROLE ARR_DASHBOARD_VIEWER;
GRANT SELECT ON ALL VIEWS  IN SCHEMA ARR_WAREHOUSE.ARR_ANALYTICS TO ROLE ARR_DASHBOARD_VIEWER;
GRANT USAGE  ON WAREHOUSE AI_WH                             TO ROLE ARR_DASHBOARD_VIEWER;

-- Required for the AI Assistant tab
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ARR_DASHBOARD_VIEWER;

-- Required only for the live SPCS URL (Option A)
USE ROLE ACCOUNTADMIN;
GRANT USAGE ON SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE
    TO ROLE ARR_DASHBOARD_VIEWER;

-- Assign to the person
USE ROLE USERADMIN;
GRANT ROLE ARR_DASHBOARD_VIEWER TO USER THEIR_USERNAME;
```

Verify it worked:

```sql
SHOW GRANTS TO ROLE ARR_DASHBOARD_VIEWER;
```

Anyone already holding `ACCOUNTADMIN` or `SYSADMIN` on this account has access
automatically and needs none of the above.

---

## Part 2 — Making Changes

### Which file do I edit?

There are three variants of the same dashboard. Edit the one matching how you run it.

| File | Runs on | Connects via |
|---|---|---|
| `app.py` | Your laptop | `connections.toml` |
| `streamlit_app.py` | Streamlit in Snowflake | Active session |
| `spcs_app.py` | SPCS container | OAuth token file |

**A change to one is not a change to the others.** If you fix a chart in `app.py` and
the fix should reach everyone, apply the same edit to the other two.

### Standard workflow

```bash
# 1. Branch off develop
git checkout develop
git pull
git checkout -b feature/your-change

# 2. Edit, then test locally
streamlit run app.py

# 3. Commit and push
git add -A
git commit -m "Describe what changed and why"
git push -u origin feature/your-change
```

Then open a pull request into `develop` on GitHub.

Set your Git identity first if you have not already, so commits carry your name rather
than your machine hostname:

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@company.com"
```

### Common changes

**Adding a chart or metric.** Charts live inside `with tab1:` … `with tab6:` blocks.
Find the tab, add a Plotly figure, and follow the existing colour constants at the top of
the file rather than introducing new hex values.

**Changing a business metric definition.** Do not edit it in Python. Metric logic lives in
the SQL views (`sql/003_create_views.sql`), so a change there reaches every consumer —
all three app variants, plus any future BI tool. Edit the view, re-run that script, and
the dashboards pick it up on next load.

**Pointing at real production data.** Edit the view definitions to select from production
tables instead of the sample `FACT_*` tables. Application code needs no change, because
it reads views rather than tables.

**Changing the colour theme.** Local theme is `.streamlit/config.toml`. Chart colours are
constants near the top of each app file.

### After changing `streamlit_app.py` (SiS)

Either paste the updated code into the Snowsight editor, or:

```bash
snow streamlit deploy --replace --connection SPCS
```

### After changing `spcs_app.py` (SPCS)

The container must be rebuilt and the service restarted:

```bash
export SF_REGISTRY="<your-account>-spcs.registry.snowflakecomputing.com"
./deploy.sh
```

Then pick up the new image:

```sql
USE ROLE ACCOUNTADMIN;
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE
    FROM @ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_STAGE
    SPECIFICATION_FILE = 'spec.yaml';
```

---

## Starting and Stopping the Service

**A running SPCS service prevents its compute pool from auto-suspending.** The pool bills
continuously while the service is up, regardless of the auto-suspend setting. Suspend both
when the dashboard is not in use.

```sql
USE ROLE ACCOUNTADMIN;

-- Stop billing
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE SUSPEND;
ALTER COMPUTE POOL STREAMLIT_CPU_POOL SUSPEND;

-- Bring it back (pool first, then service)
ALTER COMPUTE POOL STREAMLIT_CPU_POOL RESUME;
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE RESUME;

-- Check state
SHOW SERVICES IN SCHEMA ARR_WAREHOUSE.ARR_ANALYTICS;
```

Resuming takes a minute or two before the endpoint responds.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Object does not exist or not authorized` | No grants on the schema | Run the grant block above |
| `Role 'SYSADMIN' is not granted to this user` | Hardcoded role in `app.py:95` | Change it to a role you hold |
| Live URL will not load | Service suspended | Resume the service |
| First query hangs several seconds | `AI_WH` was suspended | Normal — it is waking up |
| AI Assistant tab errors | Missing Cortex privilege | `GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER` |
| `docker: command not found` | Docker Desktop not running | Start Docker Desktop |
| Image rejected by SPCS | Built for arm64 on Apple Silicon | Rebuild with `--platform linux/amd64` |

---

## What Not to Commit

`.gitignore` already blocks these, but be aware:

- `connections.toml` — contains your account and username
- `.env`, `secrets.toml`, `*.pem`, `*.p8`, `*.key`
- Your account locator or live service URL in documentation — use `<ACCOUNT>` and
  `<SERVICE_ID>` placeholders instead
