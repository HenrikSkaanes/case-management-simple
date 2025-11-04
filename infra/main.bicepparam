// Parameters file for main.bicep deployment

using './main.bicep'

param location = 'norwayeast'
param environment = 'dev'
param postgresAdminLogin = 'caseadmin'
// Note: postgresAdminPassword must be provided at deployment time via CLI or GitHub Actions
// It is not stored in this file for security reasons
// Example: az deployment group create ... --parameters postgresAdminPassword='YourPassword'
param companyName = 'Wrangler Tax Services'
