targetScope = 'resourceGroup'

@description('Environment name: dev, staging, or prod')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Base name used in resource naming')
param baseName string = 'safecase'

@description('Azure region')
param location string = resourceGroup().location

@description('PostgreSQL administrator login')
param postgresAdminLogin string = 'safecaseadmin'

@secure()
@description('PostgreSQL administrator password')
param postgresAdminPassword string

@description('App Service Linux SKU')
param appServiceSku string = environment == 'prod' ? 'P1v3' : 'B1'

var namePrefix = '${baseName}-${environment}'
var tags = {
  app: 'safecase'
  env: environment
  managedBy: 'bicep'
  dataClassification: environment == 'prod' ? 'confidential' : 'internal'
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${namePrefix}-api'
  location: location
  tags: tags
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
  }
}

module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    principalId: identity.properties.principalId
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
  }
}

module postgres 'modules/postgresql.bicep' = {
  name: 'postgres'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    administratorLogin: postgresAdminLogin
    administratorPassword: postgresAdminPassword
    skuTier: environment == 'prod' ? 'GeneralPurpose' : 'Burstable'
    skuName: environment == 'prod' ? 'Standard_D2ds_v5' : 'Standard_B1ms'
  }
}

module appService 'modules/app-service.bicep' = {
  name: 'appService'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    skuName: appServiceSku
    userAssignedIdentityId: identity.id
    userAssignedIdentityClientId: identity.properties.clientId
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    keyVaultUri: keyVault.outputs.vaultUri
  }
}

output apiHostName string = appService.outputs.defaultHostName
output keyVaultUri string = keyVault.outputs.vaultUri
output postgresFqdn string = postgres.outputs.fqdn
output storageAccountName string = storage.outputs.accountName
output managedIdentityClientId string = identity.properties.clientId
