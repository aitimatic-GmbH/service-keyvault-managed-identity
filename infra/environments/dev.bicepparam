using '../main.bicep'

param location = 'westeurope'
param environmentName = 'dev'
param projectName = 'kvmidev'
param tags = {
  environment: 'dev'
  project: 'keyvault-managed-identity'
  managedBy: 'bicep'
}
param deployWebApp = false
param webAppSkuName = 'F1'
param deployNetworking = false
param deployFunctions = false
