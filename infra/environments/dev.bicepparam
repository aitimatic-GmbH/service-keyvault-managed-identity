using '../main.bicep'

param location = 'germanywestcentral'
param environmentName = 'dev'
param projectName = 'kvmi'
param tags = {
  environment: 'dev'
  project: 'keyvault-managed-identity'
  managedBy: 'bicep'
}
