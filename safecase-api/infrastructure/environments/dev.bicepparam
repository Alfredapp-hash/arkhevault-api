using '../bicep/main.bicep'

param environment = 'dev'
param baseName = 'safecase'
// Provide at deploy time:
// az deployment group create ... --parameters postgresAdminPassword=***
param postgresAdminPassword = ''
