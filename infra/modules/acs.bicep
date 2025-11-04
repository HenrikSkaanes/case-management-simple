// Azure Communication Services module

param environment string
param tags object

var emailServiceName = 'email-cm-${environment}-${uniqueString(resourceGroup().id)}'
var acsName = 'acs-cm-${environment}-${uniqueString(resourceGroup().id)}'
var domainName = 'AzureManagedDomain'

// Email Communication Service
resource emailService 'Microsoft.Communication/emailServices@2023-04-01' = {
  name: emailServiceName
  location: 'global'
  tags: tags
  properties: {
    dataLocation: 'Europe'
  }
}

// Azure Managed Domain
resource emailDomain 'Microsoft.Communication/emailServices/domains@2023-04-01' = {
  parent: emailService
  name: domainName
  location: 'global'
  tags: tags
  properties: {
    domainManagement: 'AzureManaged'
  }
}

// Communication Service
resource communicationService 'Microsoft.Communication/communicationServices@2023-04-01' = {
  name: acsName
  location: 'global'
  tags: tags
  properties: {
    dataLocation: 'Europe'
    linkedDomains: [
      emailDomain.id
    ]
  }
}

output acsName string = communicationService.name
output acsEndpoint string = 'https://${communicationService.properties.hostName}'
output acsId string = communicationService.id
output senderEmail string = 'DoNotReply@${emailDomain.properties.mailFromSenderDomain}'
