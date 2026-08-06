#!/bin/bash
# =============================================================
# ARR Dashboard - SPCS Deployment Script
# Run this after installing Docker Desktop
# =============================================================

set -e

# Variables
REGISTRY="se58322-spcs.registry.snowflakecomputing.com"
REPO="arr_warehouse/arr_analytics/arr_dashboard_repo"
IMAGE_NAME="arr-dashboard"
TAG="latest"
FULL_IMAGE="${REGISTRY}/${REPO}/${IMAGE_NAME}:${TAG}"

echo "============================================="
echo "ARR Dashboard - SPCS Deployment"
echo "============================================="

# Step 1: Login to Snowflake Docker registry
echo ""
echo "[1/4] Logging into Snowflake registry..."
docker login ${REGISTRY} -u DEMO_SHARED_USER
# When prompted, enter your Snowflake password or use:
# echo "<password>" | docker login ${REGISTRY} -u DEMO_SHARED_USER --password-stdin

# Step 2: Build Docker image
echo ""
echo "[2/4] Building Docker image..."
docker build --platform linux/amd64 -t ${IMAGE_NAME} .

# Step 3: Tag image for Snowflake registry
echo ""
echo "[3/4] Tagging image for Snowflake registry..."
docker tag ${IMAGE_NAME} ${FULL_IMAGE}

# Step 4: Push to Snowflake registry
echo ""
echo "[4/4] Pushing image to Snowflake..."
docker push ${FULL_IMAGE}

echo ""
echo "============================================="
echo "Image pushed successfully!"
echo "Image: ${FULL_IMAGE}"
echo ""
echo "Next: Run this SQL in Snowflake to start the service:"
echo ""
echo "  USE ROLE SYSADMIN;"
echo "  ALTER COMPUTE POOL STREAMLIT_CPU_POOL RESUME;"
echo ""
echo "  CREATE SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE"
echo "    IN COMPUTE POOL STREAMLIT_CPU_POOL"
echo "    FROM @ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_STAGE"
echo "    SPECIFICATION_FILE = 'spec.yaml'"
echo "    MIN_INSTANCES = 1"
echo "    MAX_INSTANCES = 1;"
echo ""
echo "  -- Get the endpoint URL:"
echo "  SHOW ENDPOINTS IN SERVICE ARR_WAREHOUSE.ARR_ANALYTICS.ARR_DASHBOARD_SERVICE;"
echo "============================================="
