using '../main.bicep'

param location = 'westeurope'
param environmentName = 'prod'
param projectName = 'kvmiprd'
param tags = {
  environment: 'prod'
  project: 'keyvault-managed-identity'
  managedBy: 'bicep'
}
param deployWebApp = true
param webAppSkuName = 'F1'
param deployNetworking = true
param deployFunctions = true
