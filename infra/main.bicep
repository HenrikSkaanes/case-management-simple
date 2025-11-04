// Main infrastructure deployment for Simple Case Management System
// Uses Standard PostgreSQL tier (no auto-shutdown) and managed identities

targetScope = 'resourceGroup'

@description('The location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('PostgreSQL administrator login')
@secure()
param postgresAdminLogin string

@description('PostgreSQL administrator password')
@secure()
param postgresAdminPassword string

@description('Company name for branding')
param companyName string = 'Wrangler Tax Services'

// Variables
var tags = {
  Environment: environment
  Application: 'CaseManagement'
  ManagedBy: 'Bicep'
  AutoStop: 'Disabled'
}

// Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    location: location
    environment: environment
    tags: tags
  }
}

// PostgreSQL Flexible Server (Standard tier - no auto-shutdown)
module postgres 'modules/postgres.bicep' = {
  name: 'postgres-deployment'
  params: {
    location: location
    environment: environment
    adminLogin: postgresAdminLogin
    adminPassword: postgresAdminPassword
    tags: tags
  }
}

// Azure Communication Services
module acs 'modules/acs.bicep' = {
  name: 'acs-deployment'
  params: {
    environment: environment
    tags: tags
  }
}

// Container Apps Environment
module containerAppEnv 'modules/container-app-env.bicep' = {
  name: 'containerapp-env-deployment'
  params: {
    location: location
    environment: environment
    tags: tags
  }
}

// Backend Container App with Managed Identity
module backendApp 'modules/container-app.bicep' = {
  name: 'backend-app-deployment'
  params: {
    location: location
    environment: environment
    containerAppEnvId: containerAppEnv.outputs.containerAppEnvId
    acrName: acr.outputs.acrName
    postgresServerName: postgres.outputs.serverName
    postgresDatabaseName: postgres.outputs.databaseName
    postgresAdminLogin: postgresAdminLogin
    postgresAdminPassword: postgresAdminPassword
    acsEndpoint: acs.outputs.acsEndpoint
    acsSenderEmail: acs.outputs.senderEmail
    companyName: companyName
    tags: tags
  }
}

// Grant Managed Identity permissions to ACR
module acrRoleAssignment 'modules/role-assignment-acr.bicep' = {
  name: 'acr-role-assignment'
  params: {
    acrName: acr.outputs.acrName
    principalId: backendApp.outputs.managedIdentityPrincipalId
  }
}

// Grant Managed Identity permissions to ACS
module acsRoleAssignment 'modules/role-assignment-acs.bicep' = {
  name: 'acs-role-assignment'
  params: {
    acsName: acs.outputs.acsName
    principalId: backendApp.outputs.managedIdentityPrincipalId
  }
}

// Outputs
output acrLoginServer string = acr.outputs.loginServer
output acrName string = acr.outputs.acrName
output postgresServerFqdn string = postgres.outputs.serverFqdn
output postgresDatabaseName string = postgres.outputs.databaseName
output acsEndpoint string = acs.outputs.acsEndpoint
output acsSenderEmail string = acs.outputs.senderEmail
output backendApiUrl string = backendApp.outputs.apiUrl
output backendManagedIdentityPrincipalId string = backendApp.outputs.managedIdentityPrincipalId
