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

@description('Deploy networking: VNet, Private Endpoint, DNS (Phase 4).')
param deployNetworking bool = false

@description('Deploy Azure Functions with Managed Identity (Phase 5).')
param deployFunctions bool = false

@description('App Service Plan SKU for Web App. F1=Free, B1=Basic, S1=Standard.')
@allowed(['F1', 'B1', 'S1'])
param webAppSkuName string = 'F1'

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
var vnetName = 'vnet-${nameSuffix}'
var kvPrivateEndpointName = 'pep-kv-${nameSuffix}'
var storageAccountName = 'st${projectName}${environmentName}'
var functionPlanName = 'plan-func-${nameSuffix}'
var functionAppName = 'func-${nameSuffix}'

// ---------------------------------------------------------------------------
// Phase 2: Key Vault
// ---------------------------------------------------------------------------

module keyVault 'modules/keyvault/main.bicep' = {
  name: 'deploy-keyvault'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    publicNetworkAccess: deployNetworking ? 'Disabled' : 'Enabled'
    enablePurgeProtection: environmentName == 'prod'
  }
}

// ---------------------------------------------------------------------------
// Phase 3: Managed Identity + RBAC + Web App
// ---------------------------------------------------------------------------

module identity 'modules/identity/user-assigned.bicep' = if (deployWebApp || deployFunctions) {
  name: 'deploy-identity'
  params: {
    name: identityName
    location: location
    tags: tags
  }
}

// Key Vault Secrets User role for the Managed Identity
module kvRbac 'modules/rbac/keyvault-role.bicep' = if (deployWebApp || deployFunctions) {
  name: 'deploy-kv-rbac-identity'
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: identity!.outputs.principalId
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
    skuName: webAppSkuName
    userAssignedIdentityId: identity!.outputs.id
    userAssignedIdentityClientId: identity!.outputs.clientId
    keyVaultUri: keyVault.outputs.uri
  }
}

// ---------------------------------------------------------------------------
// Phase 4: Networking (VNet, Private Endpoint, DNS)
// ---------------------------------------------------------------------------

module vnet 'modules/networking/vnet.bicep' = if (deployNetworking) {
  name: 'deploy-vnet'
  params: {
    name: vnetName
    location: location
    tags: tags
    subnets: [
      { name: 'snet-private-endpoints', addressPrefix: '10.0.1.0/24' }
      { name: 'snet-webapp', addressPrefix: '10.0.2.0/24', delegation: 'Microsoft.Web/serverFarms' }
      { name: 'snet-functions', addressPrefix: '10.0.3.0/24', delegation: 'Microsoft.Web/serverFarms' }
      { name: 'snet-vms', addressPrefix: '10.0.4.0/24' }
    ]
  }
}

module kvDnsZone 'modules/networking/private-dns-zone.bicep' = if (deployNetworking) {
  name: 'deploy-kv-dns-zone'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    tags: tags
    vnetId: vnet!.outputs.id
  }
}

module kvPrivateEndpoint 'modules/networking/private-endpoint.bicep' = if (deployNetworking) {
  name: 'deploy-kv-private-endpoint'
  params: {
    name: kvPrivateEndpointName
    location: location
    tags: tags
    subnetId: vnet!.outputs.subnetIds['snet-private-endpoints']
    privateLinkServiceId: keyVault.outputs.id
    groupIds: ['vault']
    privateDnsZoneId: kvDnsZone!.outputs.id
  }
}

// ---------------------------------------------------------------------------
// Phase 5: Azure Functions
// ---------------------------------------------------------------------------

module functions 'modules/functions/main.bicep' = if (deployFunctions) {
  name: 'deploy-functions'
  params: {
    storageAccountName: storageAccountName
    functionPlanName: functionPlanName
    functionAppName: functionAppName
    location: location
    tags: tags
    userAssignedIdentityId: identity!.outputs.id
    userAssignedIdentityClientId: identity!.outputs.clientId
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
output webAppHostName string = deployWebApp ? webApp!.outputs.defaultHostName : ''

@description('Default hostname of the Function App.')
output functionAppHostName string = deployFunctions ? functions!.outputs.defaultHostName : ''
