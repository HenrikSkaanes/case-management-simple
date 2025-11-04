// Role assignment for Container App to use ACS

param acsName string
param principalId string

resource acs 'Microsoft.Communication/communicationServices@2023-04-01' existing = {
  name: acsName
}

// Contributor role for ACS (needed to send emails)
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acs.id, principalId, contributorRoleId)
  scope: acs
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = roleAssignment.id
