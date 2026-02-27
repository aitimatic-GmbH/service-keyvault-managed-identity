// ---------------------------------------------------------------------------
// Module: App Service (Web App) with Managed Identity
// ---------------------------------------------------------------------------
// Deploys an App Service Plan + Web App (Linux, Python) with a
// User-Assigned Managed Identity for Key Vault access.
// ---------------------------------------------------------------------------

@description('Name of the App Service Plan.')
param appServicePlanName string

@description('Name of the Web App.')
param webAppName string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object = {}

@description('App Service Plan SKU. F1=Free, B1=Basic, S1=Standard.')
@allowed(['F1', 'B1', 'S1'])
param skuName string = 'F1'

@description('Runtime stack.')
param linuxFxVersion string = 'PYTHON|3.12'

@description('Full resource ID of the User-Assigned Managed Identity.')
param userAssignedIdentityId string

@description('Client ID of the User-Assigned Managed Identity.')
param userAssignedIdentityClientId string

@description('Key Vault URI for application configuration.')
param keyVaultUri string

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: skuName
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: [
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

@description('Resource ID of the Web App.')
output id string = webApp.id

@description('Name of the Web App.')
output name string = webApp.name

@description('Default hostname (e.g. app-kvmi-dev.azurewebsites.net).')
output defaultHostName string = webApp.properties.defaultHostName
