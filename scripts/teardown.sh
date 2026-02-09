#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/teardown.sh [dev|staging|prod]
ENVIRONMENT="${1:-dev}"
RESOURCE_GROUP="rg-kvmi-${ENVIRONMENT}"
KEYVAULT_NAME="kv-kvmi-${ENVIRONMENT}"
LOCATION="germanywestcentral"

echo "WARNING: This will delete ALL resources in ${RESOURCE_GROUP}"
read -p "Are you sure? (yes/no): " confirm
[[ "$confirm" == "yes" ]] || exit 1

# Delete resource group
az group delete --name "${RESOURCE_GROUP}" --yes --no-wait

# Purge soft-deleted Key Vault (required to reuse the vault name)
echo "Purging soft-deleted Key Vault ${KEYVAULT_NAME}..."
az keyvault purge --name "${KEYVAULT_NAME}" --location "${LOCATION}" 2>/dev/null || true

echo "=== Teardown initiated ==="
