// ---------------------------------------------------------------------------
// Module: Azure Functions with Managed Identity
// ---------------------------------------------------------------------------
// Deploys a Storage Account + Consumption Plan + Function App (Linux, Python)
// with a User-Assigned Managed Identity for Key Vault access.
// ---------------------------------------------------------------------------

@description('Name of the Storage Account (max 24 chars, lowercase alphanumeric).')
@maxLength(24)
param storageAccountName string

@description('Name of the Function App Plan.')
param functionPlanName string

@description('Name of the Function App.')
param functionAppName string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object = {}

@description('Full resource ID of the User-Assigned Managed Identity.')
param userAssignedIdentityId string

@description('Client ID of the User-Assigned Managed Identity.')
param userAssignedIdentityClientId string

@description('Key Vault URI for application configuration.')
param keyVaultUri string

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource functionPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: functionPlanName
  location: location
  tags: tags
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: functionPlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.12'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: userAssignedIdentityClientId
        }
        {
          name: 'KEY_VAULT_URI'
          value: keyVaultUri
        }
      ]
    }
    keyVaultReferenceIdentity: userAssignedIdentityId
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('Resource ID of the Function App.')
output id string = functionApp.id

@description('Name of the Function App.')
output name string = functionApp.name

@description('Default hostname (e.g. func-kvmi-dev.azurewebsites.net).')
output defaultHostName string = functionApp.properties.defaultHostName
