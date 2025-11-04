// Backend Container App module with Managed Identity

param location string
param environment string
param containerAppEnvId string
param acrName string
param postgresServerName string
param postgresDatabaseName string
param postgresAdminLogin string
@secure()
param postgresAdminPassword string
param acsEndpoint string
param acsSenderEmail string
param companyName string
param tags object

var appName = 'ca-api-cm-${environment}'
var imageName = 'api:latest'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: appName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnvId
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        corsPolicy: {
          allowedOrigins: [
            'http://localhost:5173'
            'https://*'
          ]
          allowedMethods: [
            'GET'
            'POST'
            'PUT'
            'DELETE'
            'OPTIONS'
          ]
          allowedHeaders: [
            '*'
          ]
          allowCredentials: false
        }
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'api'
          image: '${acr.properties.loginServer}/${imageName}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'DATABASE_URL'
              value: 'postgresql://${postgresAdminLogin}:${postgresAdminPassword}@${postgresServerName}.postgres.database.azure.com:5432/${postgresDatabaseName}?sslmode=require'
            }
            {
              name: 'ACS_ENDPOINT'
              value: acsEndpoint
            }
            {
              name: 'ACS_SENDER_EMAIL'
              value: acsSenderEmail
            }
            {
              name: 'COMPANY_NAME'
              value: companyName
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: 'system' // Use system-assigned managed identity
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

output apiUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output appName string = containerApp.name
output managedIdentityPrincipalId string = containerApp.identity.principalId
