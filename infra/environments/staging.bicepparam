using '../main.bicep'

param location = 'germanywestcentral'
param environmentName = 'staging'
param projectName = 'kvmi'
param tags = {
  environment: 'staging'
  project: 'keyvault-managed-identity'
  managedBy: 'bicep'
}
param deployWebApp = true
param deployNetworking = true
