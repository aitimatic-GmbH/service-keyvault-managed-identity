using '../main.bicep'

param location = 'westeurope'
param environmentName = 'staging'
param projectName = 'kvmistg'
param tags = {
  environment: 'staging'
  project: 'keyvault-managed-identity'
  managedBy: 'bicep'
}
param deployWebApp = true
param webAppSkuName = 'F1'
param deployNetworking = true
param deployFunctions = true
