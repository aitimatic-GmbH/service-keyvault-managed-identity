// ---------------------------------------------------------------------------
// Module: User-Assigned Managed Identity
// ---------------------------------------------------------------------------
// Creates a User-Assigned Managed Identity that can be shared across
// multiple resources and exists independently of any compute resource.
// ---------------------------------------------------------------------------

@description('Name of the Managed Identity.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object = {}

// ---------------------------------------------------------------------------
// Resource
// ---------------------------------------------------------------------------

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('Full resource ID (used when assigning to compute resources).')
output id string = managedIdentity.id

@description('Object ID of the service principal (used for RBAC role assignments).')
output principalId string = managedIdentity.properties.principalId

@description('Client/Application ID (used by application code with DefaultAzureCredential).')
output clientId string = managedIdentity.properties.clientId

@description('Name of the Managed Identity.')
output name string = managedIdentity.name
