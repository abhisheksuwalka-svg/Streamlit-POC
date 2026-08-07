# SPCS Deployment Guide — ARR Dashboard

**Author:** Abhishek Suwalka

Complete record of the Docker container build and Snowpark Container Services (SPCS) deployment.

---

## Live Dashboard

**URL pattern:** `https://<SERVICE_ID>-<ACCOUNT>-spcs.snowflakecomputing.app`

Requires Snowflake login. Anyone with access to the service role can view it.

> **Note:** `<ACCOUNT>` and `<SERVICE_ID>` are placeholders. Find your actual values with:
> ```sql
> -- Your registry host (contains <ACCOUNT>)
> SHOW IMAGE REPOSITORIES IN SCHEMA ARR_WAREHOUSE.ARR_ANALYTICS;
>
> -- Your live endpoint URL (contains <SERVICE_ID>)
> SHOW ENDPOINTS IN SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE;
> ```

---

## Deployment Summary

| Component | Value |
|-----------|-------|
| Public URL | `https://<SERVICE_ID>-<ACCOUNT>-spcs.snowflakecomputing.app` |
| Service | `ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE` |
| Status | READY / Running |
| Compute Pool | `STREAMLIT_CPU_POOL` (CPU_X64_S, 1–2 nodes) |
| Image Repository | `ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_REPO` |
| Image | `arr-dashboard:latest` |
| Registry | `<ACCOUNT>-spcs.registry.snowflakecomputing.com` |
| Port | 8501 (public HTTP) |
| Query Warehouse | `AI_WH` |
| Container Resources | 512M–1G memory, 0.5–1 CPU |

---

## Files Created

| File | Purpose |
|------|---------|
| `Dockerfile` | Container build — Python 3.9-slim, Streamlit, Snowflake connector |
| `.dockerignore` | Excludes `.venv`, `.git`, SQL files, markdown from image |
| `spcs_app.py` | SPCS-compatible app using OAuth token auth |
| `spec.yaml` | SPCS service specification (image, resources, endpoints) |
| `requirements_spcs.txt` | Container Python dependencies |
| `deploy.sh` | One-click build + tag + push script |

---

## Step-by-Step: What Was Done

### Step 1: Created Snowflake Objects

```sql
USE ROLE ACCOUNTADMIN;

-- Stage to hold the service specification
CREATE STAGE IF NOT EXISTS ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_STAGE
  ENCRYPTION = (TYPE = 'SNOWFLAKE_FULL');

-- Image repository for the Docker image
CREATE IMAGE REPOSITORY IF NOT EXISTS ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_REPO;

-- Get the registry URL
SHOW IMAGE REPOSITORIES LIKE 'ARR_DASHBOARD_REPO' IN SCHEMA ARR_WAREHOUSE.ARR_ANALYTICS;
-- Returns: <ACCOUNT>-spcs.registry.snowflakecomputing.com/arr_warehouse/arr_analytics/arr_dashboard_repo
```

---

### Step 2: Created the Dockerfile

```dockerfile
FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements_spcs.txt .
RUN pip install --no-cache-dir -r requirements_spcs.txt

COPY spcs_app.py ./app.py
COPY .streamlit/ ./.streamlit/

EXPOSE 8501

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

ENTRYPOINT ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0", "--server.headless=true"]
```

---

### Step 3: Adapted the App for SPCS

The key change from the local version — SPCS injects an OAuth token at `/snowflake/session/token`:

```python
@st.cache_resource
def get_connection():
    """Connect to Snowflake using SPCS OAuth token (injected by container runtime)."""
    token_path = "/snowflake/session/token"
    if os.path.exists(token_path):
        with open(token_path, "r") as f:
            token = f.read().strip()
        conn = snowflake.connector.connect(
            host=os.environ.get("SNOWFLAKE_HOST", ""),
            account=os.environ.get("SNOWFLAKE_ACCOUNT", ""),
            token=token,
            authenticator="oauth",
            database="ARR_WAREHOUSE",
            schema="ARR_ANALYTICS",
            warehouse=os.environ.get("SNOWFLAKE_WAREHOUSE", "AI_WH"),
        )
    else:
        # Fallback for local Docker testing
        conn = snowflake.connector.connect(
            connection_name="SPCS",
            database="ARR_WAREHOUSE",
            schema="ARR_ANALYTICS",
            warehouse="AI_WH",
            role="SYSADMIN",
        )
    return conn
```

The AI chatbot also changed — Cortex is called via SQL instead of the Python API:

```python
result = run_query(f"""
    SELECT SNOWFLAKE.CORTEX.COMPLETE('llama3.1-70b',
        '[SYSTEM]You are an ARR data analyst...[/SYSTEM]\\n[USER]{prompt}[/USER]'
    ) AS RESPONSE
""")
```

---

### Step 4: Created the Service Specification

`spec.yaml`:

```yaml
spec:
  containers:
    - name: arr-dashboard
      image: /ARR_WAREHOUSE/ARR_ANALYTICS/ARR_DASHBOARD_REPO/arr-dashboard:latest
      env:
        SNOWFLAKE_WAREHOUSE: AI_WH
      resources:
        requests:
          memory: 512M
          cpu: 0.5
        limits:
          memory: 1G
          cpu: 1
  endpoints:
    - name: dashboard
      port: 8501
      public: true
```

Uploaded to the stage:

```sql
PUT file:///path/to/spec.yaml @ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_STAGE
  AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
```

---

### Step 5: Built the Docker Image

```bash
cd /path/to/streamlit-poc
docker build --platform linux/amd64 -t arr-dashboard .
```

**Important:** `--platform linux/amd64` is required. SPCS runs on x86_64, so building on Apple Silicon without this flag produces an incompatible ARM image.

Build output: 7 layers, ~45s for pip install, image exported successfully.

---

### Step 6: Authenticated to the Registry

Since the account uses OAuth (not password auth), `docker login` alone won't work. Use the Snow CLI:

```bash
snow spcs image-registry login --connection SPCS
# Login Succeeded
```

This writes credentials into Docker's config so `docker push` works.

---

### Step 7: Tagged and Pushed the Image

```bash
docker tag arr-dashboard \
  <ACCOUNT>-spcs.registry.snowflakecomputing.com/arr_warehouse/arr_analytics/arr_dashboard_repo/arr-dashboard:latest

docker push \
  <ACCOUNT>-spcs.registry.snowflakecomputing.com/arr_warehouse/arr_analytics/arr_dashboard_repo/arr-dashboard:latest
```

Result: `latest: digest: sha256:24c931a3c86fa8851a8905e241eb50f16f745294d4a45a2e5b1bd5e82d044d2f size: 856`

---

### Step 8: Resumed the Compute Pool

```sql
ALTER COMPUTE POOL STREAMLIT_CPU_POOL RESUME;
```

---

### Step 9: Created the Service

```sql
USE ROLE ACCOUNTADMIN;

CREATE SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE
  IN COMPUTE POOL STREAMLIT_CPU_POOL
  FROM @ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_STAGE
  SPECIFICATION_FILE = 'spec.yaml'
  MIN_INSTANCES = 1
  MAX_INSTANCES = 1
  QUERY_WAREHOUSE = AI_WH;
```

---

### Step 10: Verified and Got the URL

```sql
-- Check status (took ~45s to become READY)
SELECT SYSTEM$GET_SERVICE_STATUS('ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE');
-- {"status":"READY","message":"Running","containerName":"arr-dashboard",...}

-- Get the public endpoint (took ~2 min to provision)
SHOW ENDPOINTS IN SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE;
-- dashboard | 8501 | HTTP | true | <SERVICE_ID>-<ACCOUNT>-spcs.snowflakecomputing.app
```

---

## Cost Management

### Current Auto-Suspend Settings

| Resource | Auto-Suspend | Auto-Resume | Notes |
|----------|-------------|-------------|-------|
| Warehouse `AI_WH` | 300s (5 min) | Yes | Suspends after 5 min of no queries |
| Compute Pool `STREAMLIT_CPU_POOL` | 3600s (1 hour) | Yes | **Only suspends when zero services are running** |

### Important: Running Service Keeps the Pool Awake

A running SPCS service **prevents the compute pool from auto-suspending**. The pool's `auto_suspend_secs` only applies when there are no active services.

**This means:** while the service is RUNNING, the pool stays ACTIVE and consumes credits continuously — even with no users on the dashboard.

### To Stop Credit Consumption

```sql
-- Suspend the service (pool will then auto-suspend after its timeout)
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE SUSPEND;

-- Or suspend both immediately
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE SUSPEND;
ALTER COMPUTE POOL STREAMLIT_CPU_POOL SUSPEND;
```

### To Bring It Back

```sql
ALTER COMPUTE POOL STREAMLIT_CPU_POOL RESUME;
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE RESUME;
```

### Optional: Lower the Pool Auto-Suspend

```sql
ALTER COMPUTE POOL STREAMLIT_CPU_POOL SET AUTO_SUSPEND_SECS = 600;  -- 10 min
```

---

## Operational Commands

```sql
-- Service status
SELECT SYSTEM$GET_SERVICE_STATUS('ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE');

-- Container logs (last 50 lines)
SELECT SYSTEM$GET_SERVICE_LOGS(
  'ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE', 0, 'arr-dashboard', 50
);

-- Endpoint URL
SHOW ENDPOINTS IN SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE;

-- Grant access to another role
GRANT SERVICE ROLE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE!ALL_ENDPOINTS_USAGE
  TO ROLE <your_role>;

-- Suspend / Resume
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE SUSPEND;
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE RESUME;

-- Drop the service
DROP SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE;
```

---

## Redeploying After Code Changes

```bash
# 1. Rebuild
docker build --platform linux/amd64 -t arr-dashboard .

# 2. Retag
docker tag arr-dashboard \
  <ACCOUNT>-spcs.registry.snowflakecomputing.com/arr_warehouse/arr_analytics/arr_dashboard_repo/arr-dashboard:latest

# 3. Login (if session expired)
snow spcs image-registry login --connection SPCS

# 4. Push
docker push \
  <ACCOUNT>-spcs.registry.snowflakecomputing.com/arr_warehouse/arr_analytics/arr_dashboard_repo/arr-dashboard:latest
```

Then in Snowflake:

```sql
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE
  FROM @ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_STAGE
  SPECIFICATION_FILE = 'spec.yaml';
```

Or simply:

```sql
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE SUSPEND;
ALTER SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE RESUME;
```

---

## Issues Encountered and Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| `Insufficient privileges ... CREATE IMAGE REPOSITORY` | Default role was `PUBLIC` | `USE ROLE ACCOUNTADMIN` |
| `Insufficient privileges ... CREATE SERVICE` | Same | `USE ROLE ACCOUNTADMIN` |
| `docker: command not found` | Docker Desktop not started / PATH not refreshed | Start Docker Desktop, reopen terminal |
| Registry auth would fail with plain `docker login` | Account uses OAuth, not password | `snow spcs image-registry login` |
| Endpoint showed "provisioning in progress" | Normal — takes 1–3 min | Wait and re-run `SHOW ENDPOINTS` |

---

## Three Deployment Options Compared

| | Local Streamlit | Streamlit in Snowflake (SiS) | SPCS (this deployment) |
|---|---|---|---|
| File | `app.py` | `streamlit_app.py` | `spcs_app.py` |
| Auth | `connections.toml` | Automatic session | OAuth token file |
| Hosting | Your laptop | Managed by Snowflake | Container on compute pool |
| URL | `localhost:8501` | Inside Snowsight | Public `*.snowflakecomputing.app` |
| Packages | `requirements.txt` | `environment.yml` (allowlist only) | `Dockerfile` (anything) |
| Cost | Free (warehouse only) | Warehouse credits | Compute pool + warehouse credits |
| External access | No | No | Yes |
| Best for | Development | Internal dashboards | Client-facing / custom deps |
