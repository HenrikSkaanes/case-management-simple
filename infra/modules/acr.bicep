// Azure Container Registry module

param location string
param environment string
param tags object

var acrName = 'acrcm${environment}${uniqueString(resourceGroup().id)}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false // Use managed identity instead
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

output acrName string = acr.name
output loginServer string = acr.properties.loginServer
output acrId string = acr.id
