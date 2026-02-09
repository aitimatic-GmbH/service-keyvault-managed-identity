// ---------------------------------------------------------------------------
// Module: Key Vault RBAC Role Assignment
// ---------------------------------------------------------------------------
// Assigns a built-in Key Vault role to a principal on a specific vault.
//
// Built-in roles:
//   Key Vault Administrator        00482a5a-887f-4fb3-b363-3b7fe8e74483
//   Key Vault Secrets Officer      b86a8fe4-44ce-4948-aee5-eccb2c155cd7
//   Key Vault Secrets User         4633458b-17de-408a-b874-0445c86b69e6
//   Key Vault Crypto Officer       14b46e9e-c2b7-41b4-b07b-48a6ebf60603
//   Key Vault Certificates Officer a4417e6f-fecd-4de8-b567-7b0420556985
//   Key Vault Reader               21090545-7ca7-4776-b22c-e363652d74d2
// ---------------------------------------------------------------------------

@description('Name of the existing Key Vault.')
param keyVaultName string

@description('Object ID of the principal receiving access.')
param principalId string

@description('Principal type. Set explicitly to avoid replication race conditions.')
@allowed(['ServicePrincipal', 'User', 'Group', 'ForeignGroup'])
param principalType string

@description('GUID of the built-in role definition.')
param roleDefinitionId string

// ---------------------------------------------------------------------------
// Existing resource reference
// ---------------------------------------------------------------------------

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// ---------------------------------------------------------------------------
// Role Assignment
// ---------------------------------------------------------------------------
// Name uses guid() with deterministic inputs for idempotent deployments.
// Same inputs -> same GUID -> no duplicate assignments on re-deploy.
// ---------------------------------------------------------------------------

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, principalId, roleDefinitionId)
  scope: keyVault
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}
