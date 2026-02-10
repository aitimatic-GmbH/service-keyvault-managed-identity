// ---------------------------------------------------------------------------
// Module: Private DNS Zone
// ---------------------------------------------------------------------------
// Creates a Private DNS Zone and links it to a VNet.
// DNS Zone names are fixed per service type:
//   Key Vault:    privatelink.vaultcore.azure.net
//   App Service:  privatelink.azurewebsites.net
//   Storage Blob: privatelink.blob.core.windows.net
//   SQL Database: privatelink.database.windows.net
// ---------------------------------------------------------------------------

@description('Private DNS Zone name (e.g. privatelink.vaultcore.azure.net).')
param name string

@description('Resource tags.')
param tags object = {}

@description('Resource ID of the VNet to link.')
param vnetId string

@description('Name of the VNet link.')
param vnetLinkName string = 'vnet-link'

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// Private DNS Zones are global resources (no location parameter)
resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'global'
  tags: tags
}

// Link the DNS Zone to the VNet so resources in the VNet resolve private IPs
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZone
  name: vnetLinkName
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('Resource ID of the Private DNS Zone.')
output id string = dnsZone.id

@description('Name of the Private DNS Zone.')
output name string = dnsZone.name
