// ---------------------------------------------------------------------------
// Module: Virtual Network + Subnets
// ---------------------------------------------------------------------------
// Deploys a VNet with configurable subnets. Subnets support optional
// delegations (required for App Service VNet integration).
// ---------------------------------------------------------------------------

@description('Name of the Virtual Network.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object = {}

@description('VNet address space.')
param addressPrefix string = '10.0.0.0/16'

@description('Subnet definitions.')
param subnets subnetType[]

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

@description('Subnet configuration.')
type subnetType = {
  @description('Subnet name.')
  name: string

  @description('Subnet address prefix (e.g. 10.0.1.0/24).')
  addressPrefix: string

  @description('Optional service delegation (e.g. Microsoft.Web/serverFarms).')
  delegation: string?
}

// ---------------------------------------------------------------------------
// Resource
// ---------------------------------------------------------------------------

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        delegations: subnet.?delegation != null ? [
          {
            name: '${subnet.name}-delegation'
            properties: {
              serviceName: subnet.delegation!
            }
          }
        ] : []
      }
    }]
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('Resource ID of the VNet.')
output id string = vnet.id

@description('Name of the VNet.')
output name string = vnet.name

@description('Map of subnet name to subnet resource ID.')
output subnetIds object = reduce(
  map(vnet.properties.subnets, s => { '${s.name}': s.id }),
  {},
  (cur, next) => union(cur, next)
)
