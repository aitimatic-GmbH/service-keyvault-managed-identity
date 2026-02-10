// ---------------------------------------------------------------------------
// Module: Private Endpoint
// ---------------------------------------------------------------------------
// Creates a Private Endpoint for an Azure service and registers it
// in a Private DNS Zone for automatic name resolution.
// ---------------------------------------------------------------------------

@description('Name of the Private Endpoint.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object = {}

@description('Resource ID of the subnet for the Private Endpoint.')
param subnetId string

@description('Resource ID of the service to connect to (e.g. Key Vault).')
param privateLinkServiceId string

@description('Service-specific group IDs (e.g. ["vault"] for Key Vault).')
param groupIds array

@description('Resource ID of the Private DNS Zone.')
param privateDnsZoneId string

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-connection'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}

// DNS Zone Group: automatically creates A records in the Private DNS Zone
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('Resource ID of the Private Endpoint.')
output id string = privateEndpoint.id

@description('Name of the Private Endpoint.')
output name string = privateEndpoint.name
