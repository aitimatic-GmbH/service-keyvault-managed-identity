#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/validate.sh [dev|staging|prod]
ENVIRONMENT="${1:-dev}"
RESOURCE_GROUP="rg-kvmi-${ENVIRONMENT}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="${SCRIPT_DIR}/../infra"

LOCATION="germanywestcentral"

echo "=== Validating environment: ${ENVIRONMENT} ==="

# Ensure resource group exists (required for what-if)
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags environment="${ENVIRONMENT}" project="keyvault-managed-identity" \
  --output none

az deployment group what-if \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "${INFRA_DIR}/main.bicep" \
  --parameters "${INFRA_DIR}/environments/${ENVIRONMENT}.bicepparam"

echo "=== Validation complete ==="
