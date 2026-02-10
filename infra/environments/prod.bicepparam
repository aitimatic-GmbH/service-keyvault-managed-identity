using '../main.bicep'

param location = 'germanywestcentral'
param environmentName = 'prod'
param projectName = 'kvmi'
param tags = {
  environment: 'prod'
  project: 'keyvault-managed-identity'
  managedBy: 'bicep'
}
param deployWebApp = true
param deployNetworking = true
