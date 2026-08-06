#!/bin/bash
# =============================================================
# ARR Dashboard - SPCS Deployment Script
# =============================================================
# BEFORE RUNNING: set the two variables below for your account.
#
# Find your registry host with:
#   SHOW IMAGE REPOSITORIES IN SCHEMA ARR_WAREHOUSE.ARR_ANALYTICS;
#
# Or override at run time:
#   SF_REGISTRY="abc12345-spcs.registry.snowflakecomputing.com" \
#   SF_USER="MY_USER" ./deploy.sh
# =============================================================

set -e

# --- Configure these (or export them before running) ---
REGISTRY="${SF_REGISTRY:-<YOUR_ACCOUNT>-spcs.registry.snowflakecomputing.com}"
SF_USER="${SF_USER:-<YOUR_SNOWFLAKE_USER>}"
SF_CONNECTION="${SF_CONNECTION:-SPCS}"

# --- Fixed values ---
REPO="arr_warehouse/arr_analytics/arr_dashboard_repo"
IMAGE_NAME="arr-dashboard"
TAG="latest"
FULL_IMAGE="${REGISTRY}/${REPO}/${IMAGE_NAME}:${TAG}"

# --- Guard against unconfigured placeholders ---
if [[ "${REGISTRY}" == *"<YOUR_ACCOUNT>"* ]]; then
  echo "ERROR: REGISTRY is not configured."
  echo "Set SF_REGISTRY env var or edit this script."
  echo "Find it with: SHOW IMAGE REPOSITORIES IN SCHEMA ARR_WAREHOUSE.ARR_ANALYTICS;"
  exit 1
fi

echo "============================================="
echo "ARR Dashboard - SPCS Deployment"
echo "Registry: ${REGISTRY}"
echo "============================================="

# Step 1: Login to Snowflake Docker registry
# Uses Snow CLI so OAuth / SSO connections work without a password.
echo ""
echo "[1/4] Logging into Snowflake registry..."
snow spcs image-registry login --connection "${SF_CONNECTION}"

# Step 2: Build Docker image
# --platform linux/amd64 is required: SPCS runs x86_64.
echo ""
echo "[2/4] Building Docker image..."
docker build --platform linux/amd64 -t ${IMAGE_NAME} .

# Step 3: Tag image for Snowflake registry
echo ""
echo "[3/4] Tagging image..."
docker tag ${IMAGE_NAME} ${FULL_IMAGE}

# Step 4: Push to Snowflake registry
echo ""
echo "[4/4] Pushing image to Snowflake..."
docker push ${FULL_IMAGE}

echo ""
echo "============================================="
echo "Image pushed successfully."
echo ""
echo "Next: run this SQL in Snowflake to start the service:"
echo ""
echo "  USE ROLE ACCOUNTADMIN;"
echo "  ALTER COMPUTE POOL STREAMLIT_CPU_POOL RESUME;"
echo ""
echo "  CREATE SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE"
echo "    IN COMPUTE POOL STREAMLIT_CPU_POOL"
echo "    FROM @ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_STAGE"
echo "    SPECIFICATION_FILE = 'spec.yaml'"
echo "    MIN_INSTANCES = 1"
echo "    MAX_INSTANCES = 1"
echo "    QUERY_WAREHOUSE = AI_WH;"
echo ""
echo "  -- Then get your dashboard URL:"
echo "  SHOW ENDPOINTS IN SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE;"
echo "============================================="
