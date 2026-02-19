// ---------------------------------------------------------------------------
// Module: Azure Key Vault
// ---------------------------------------------------------------------------
// Deploys an Azure Key Vault with RBAC authorization, soft-delete,
// purge protection, and network ACLs (default deny, bypass AzureServices).
// ---------------------------------------------------------------------------

@description('Name of the Key Vault. Must be globally unique, 3-24 chars, alphanumeric and hyphens.')
@minLength(3)
@maxLength(24)
param name string

@description('Azure region for the Key Vault.')
param location string

@description('Resource tags.')
param tags object = {}

@description('SKU: standard (secrets) or premium (HSM-backed keys).')
@allowed(['standard', 'premium'])
param skuName string = 'standard'

@description('Enable RBAC authorization instead of access policies.')
param enableRbacAuthorization bool = true

@description('Enable soft-delete (required for compliance).')
param enableSoftDelete bool = true

@description('Soft-delete retention in days.')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Enable purge protection. One-way switch -- cannot be disabled once enabled.')
param enablePurgeProtection bool = true

@description('Public network access: Enabled or Disabled. Set to Disabled when using Private Endpoints.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

// ---------------------------------------------------------------------------
// Resource
// ---------------------------------------------------------------------------

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection ? true : null
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('Resource ID of the Key Vault.')
output id string = keyVault.id

@description('Name of the Key Vault.')
output name string = keyVault.name

@description('Vault URI (e.g. https://kv-name.vault.azure.net/).')
output uri string = keyVault.properties.vaultUri
