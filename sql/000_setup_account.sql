/*
================================================================================
ARR SEMANTIC MODEL - ACCOUNT SETUP (RUN THIS FIRST)
================================================================================
Creates the database and warehouse that scripts 001-004 assume already exist.

Run this BEFORE 001_create_schema.sql if you are setting up in a fresh
Snowflake account. Everything here is self-contained - no external
dependencies, no reference to any other database.

Author: Abhishek Suwalka
================================================================================
*/

-- Use any role that can create databases and warehouses.
-- SYSADMIN is standard; change it if your account uses a different role.
USE ROLE SYSADMIN;

-- ============================================================================
-- DATABASE
-- ============================================================================
CREATE DATABASE IF NOT EXISTS ARR_WAREHOUSE
    COMMENT = 'Self-contained ARR analytics model for the dashboard POC';

-- ============================================================================
-- WAREHOUSE
-- ============================================================================
-- XSMALL is ample for this dataset (roughly 200 rows total).
-- AUTO_SUSPEND = 60 keeps credit consumption negligible.
CREATE WAREHOUSE IF NOT EXISTS ARR_WH
    WAREHOUSE_SIZE       = 'XSMALL'
    AUTO_SUSPEND         = 60
    AUTO_RESUME          = TRUE
    INITIALLY_SUSPENDED  = TRUE
    COMMENT = 'Compute for the ARR dashboard POC';

-- ============================================================================
-- SET CONTEXT
-- ============================================================================
USE DATABASE ARR_WAREHOUSE;
USE WAREHOUSE ARR_WH;

-- ============================================================================
-- VERIFY
-- ============================================================================
SELECT
    CURRENT_ACCOUNT()   AS ACCOUNT,
    CURRENT_ROLE()      AS ROLE,
    CURRENT_DATABASE()  AS DATABASE,
    CURRENT_WAREHOUSE() AS WAREHOUSE;

/*
================================================================================
NEXT STEPS
================================================================================
Run these in order:
    002 -> 001_create_schema.sql        (12 tables)
    003 -> 002_insert_sample_data.sql   (sample data)
    004 -> 003_create_views.sql         (7 analytical views)
    005 -> 004_semantic_layer.sql       (5 semantic views)

Then configure the dashboard. In app.py, set:
    SF_WAREHOUSE = "ARR_WH"
    SF_ROLE      = "SYSADMIN"    (or "" to use your default role)
================================================================================
*/
