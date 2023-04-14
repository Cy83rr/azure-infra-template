// =========== storage.bicep ===========

// targetScope = 'resourceGroup' - not needed since it is the default value

param storageAccountName string

param environmentSku object 

@description('The Azure region into which the resources should be deployed.')
param location string

resource stg 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: environmentSku
  kind: 'StorageV2'
}
