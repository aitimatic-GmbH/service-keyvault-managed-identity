#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/deploy.sh [dev|staging|prod]
ENVIRONMENT="${1:-dev}"
RESOURCE_GROUP="rg-kvmi-${ENVIRONMENT}"
LOCATION="germanywestcentral"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="${SCRIPT_DIR}/../infra"

echo "=== Deploying environment: ${ENVIRONMENT} ==="

# Create resource group if it doesn't exist
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags environment="${ENVIRONMENT}" project="keyvault-managed-identity"

# Deploy Bicep template (Incremental mode: add/update only, never delete)
az deployment group create \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "${INFRA_DIR}/main.bicep" \
  --parameters "${INFRA_DIR}/environments/${ENVIRONMENT}.bicepparam" \
  --name "deploy-$(date +%Y%m%d-%H%M%S)" \
  --verbose

echo "=== Deployment complete ==="
