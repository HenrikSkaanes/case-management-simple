// Container Apps Environment module

param location string
param environment string
param tags object

var envName = 'cae-cm-${environment}-${uniqueString(resourceGroup().id)}'

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: envName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'azure-monitor'
    }
    zoneRedundant: false
  }
}

output containerAppEnvId string = containerAppEnv.id
output containerAppEnvName string = containerAppEnv.name
