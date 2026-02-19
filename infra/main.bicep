// ---------------------------------------------------------------------------
// Root Orchestration: Key Vault + Managed Identity Service
// ---------------------------------------------------------------------------
// Entry point for az deployment group create.
// Composes modules and uses feature flags for incremental deployment.
// ---------------------------------------------------------------------------

targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Azure region for all resources.')
param location string

@description('Environment name (dev, staging, prod).')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Short project prefix for resource naming.')
@maxLength(10)
param projectName string = 'kvmi'

@description('Tags applied to all resources.')
param tags object = {}

// ---------------------------------------------------------------------------
// Naming Convention
// ---------------------------------------------------------------------------
// Pattern: {abbreviation}-{project}-{environment}
// See: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

var nameSuffix = '${projectName}-${environmentName}'
var keyVaultName = 'kv-${nameSuffix}'

// ---------------------------------------------------------------------------
// Phase 2: Key Vault
// ---------------------------------------------------------------------------

module keyVault 'modules/keyvault/main.bicep' = {
  name: 'deploy-keyvault'
  params: {
    name: keyVaultName
    location: location
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('Name of the deployed Key Vault.')
output keyVaultName string = keyVault.outputs.name

@description('URI of the deployed Key Vault.')
output keyVaultUri string = keyVault.outputs.uri
