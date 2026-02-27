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

@description('Deploy Web App with Managed Identity (Phase 3).')
param deployWebApp bool = false

// ---------------------------------------------------------------------------
// Naming Convention
// ---------------------------------------------------------------------------
// Pattern: {abbreviation}-{project}-{environment}
// See: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

var nameSuffix = '${projectName}-${environmentName}'
var keyVaultName = 'kv-${nameSuffix}'
var identityName = 'id-${nameSuffix}'
var appServicePlanName = 'asp-${nameSuffix}'
var webAppName = 'app-${nameSuffix}'

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
// Phase 3: Managed Identity + RBAC + Web App
// ---------------------------------------------------------------------------

module identity 'modules/identity/user-assigned.bicep' = if (deployWebApp) {
  name: 'deploy-identity'
  params: {
    name: identityName
    location: location
    tags: tags
  }
}

// Key Vault Secrets User role for the Managed Identity
module kvRbacWebApp 'modules/rbac/keyvault-role.bicep' = if (deployWebApp) {
  name: 'deploy-kv-rbac-webapp'
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: identity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6'
  }
}

module webApp 'modules/webapp/main.bicep' = if (deployWebApp) {
  name: 'deploy-webapp'
  params: {
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    location: location
    tags: tags
    userAssignedIdentityId: identity.outputs.id
    userAssignedIdentityClientId: identity.outputs.clientId
    keyVaultUri: keyVault.outputs.uri
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('Name of the deployed Key Vault.')
output keyVaultName string = keyVault.outputs.name

@description('URI of the deployed Key Vault.')
output keyVaultUri string = keyVault.outputs.uri

@description('Default hostname of the Web App.')
output webAppHostName string = deployWebApp ? webApp.outputs.defaultHostName : ''
