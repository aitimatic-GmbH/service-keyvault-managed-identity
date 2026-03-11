#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/deploy.sh [dev|staging|prod]
ENVIRONMENT="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="${SCRIPT_DIR}/../infra"

LOCATION="westeurope"
RESOURCE_GROUP="rg-kvmi-${ENVIRONMENT}"

echo "=== Deploying environment: ${ENVIRONMENT} ==="

# Create resource group if it doesn't exist
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags environment="${ENVIRONMENT}" project="keyvault-managed-identity" \
  --output none

# Deploy Bicep template (Incremental mode: add/update only, never delete)
DEPLOYMENT_NAME="deploy-$(date +%Y%m%d-%H%M%S)"
az deployment group create \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "${INFRA_DIR}/main.bicep" \
  --parameters "${INFRA_DIR}/environments/${ENVIRONMENT}.bicepparam" \
  --name "${DEPLOYMENT_NAME}" \
  --verbose

echo "=== Deployment complete ==="
