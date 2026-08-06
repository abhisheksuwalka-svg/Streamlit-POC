# ARR Dashboard 2.0 — Replacing Power BI with Real-Time Snowflake Analytics

A production-grade Streamlit dashboard that replaces Power BI for Annual Recurring Revenue (ARR) analytics, powered by live Snowflake data.

---

## Setup & Run Instructions

### Prerequisites

- Python 3.9+
- Snowflake account with access to `AI_WH` warehouse
- Snowflake connection configured in `~/.snowflake/connections.toml` (connection name: `SPCS`)

### 1. Clone the Repository

```bash
git clone https://github.com/abhisheksuwalka-svg/Streamlit-POC.git
cd Streamlit-POC
git checkout develop
```

### 2. Create Virtual Environment

```bash
python -m venv .venv
source .venv/bin/activate   # macOS/Linux
# .venv\Scripts\activate    # Windows
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Set Up Snowflake Schema (First Time Only)

Run the SQL files in order against your Snowflake account:

```bash
# Using SnowSQL or Snowsight, execute in sequence:
sql/001_create_schema.sql    # Creates database, schema, and 12 tables
sql/002_insert_sample_data.sql  # Populates with realistic sample data
sql/003_create_views.sql     # Creates 7 analytical views
sql/004_semantic_layer.sql   # Creates semantic layer views for BI tools
```

This creates:
- **Database:** `ARR_WAREHOUSE`
- **Schema:** `ARR_ANALYTICS`
- **Warehouse:** `AI_WH`
- **Role:** `SYSADMIN`

### 5. Configure Snowflake Connection

Create or edit `~/.snowflake/connections.toml` (this file lives **outside** the repo — never commit it):

```toml
[SPCS]
account = "your_account_locator"
user = "your_user"
authenticator = "externalbrowser"   # or OAUTH_AUTHORIZATION_CODE, or username_password
```

> **Security note:** This repo contains no credentials. All account identifiers, usernames,
> and service URLs in the documentation are placeholders (`<ACCOUNT>`, `<SERVICE_ID>`,
> `<YOUR_SNOWFLAKE_USER>`). Substitute your own values locally — do not commit them.
>
> `.gitignore` blocks `connections.toml`, `.env`, `secrets.toml`, `*.pem`, and `*.key`
> as a safety net.

### 6. Run the Dashboard

```bash
streamlit run app.py
```

Open **http://localhost:8501** in your browser.

---

## Project Structure

```
Streamlit-POC/
├── .streamlit/config.toml       # Streamlit theme & server config
├── app.py                       # Main dashboard application (823 lines)
├── requirements.txt             # Python dependencies
└── sql/
    ├── 001_create_schema.sql    # 12 tables with PKs/FKs
    ├── 002_insert_sample_data.sql  # Realistic sample data
    ├── 003_create_views.sql     # 7 analytical views
    ├── 004_semantic_layer.sql   # Semantic layer for BI tools
    └── erd.md                   # ER diagram + relationship docs
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Port 8501 already in use` | Run `lsof -ti:8501 \| xargs kill -9` then restart |
| `Insufficient privileges` | Switch to `SYSADMIN` role in Snowflake |
| `Connection failed` | Check `~/.snowflake/connections.toml` has valid `SPCS` entry |
| `Table does not exist` | Run `sql/001_create_schema.sql` and `002_insert_sample_data.sql` first |
