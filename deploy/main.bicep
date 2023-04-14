@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the App Service app.')
param appServiceAppName string = 'toy-${uniqueString(resourceGroup().id)}'

@description('The name of the App Service app.')
@minLength(3)
@maxLength(24)
param storageaccountName string = 'test${uniqueString(resourceGroup().id)}'


var appServicePlanName = 'toy-product-launch-plan'

@description('Name of the keyvault for secrets')
param keyVaultName string = 'secret${uniqueString(resourceGroup().id)}'

var environmentConfigurationMap = {
  Test: {
    appServicePlan: {
      sku: {
        name: 'F1'
        capacity: 1
      }
    }
    toyManualsStorageAccount: {
      sku: {
        name: 'Standard_LRS'
      }
    }
    toykeyvault: {
      objectId: 'efb46152-9a7b-485a-ad5b-bfd36d446d24'
      sku: {
        name: 'standard'
        family: 'A'
      }
    }
  }
  Production: {
    appServicePlan: {
      sku: {
        name: 'S1'
        capacity: 2
      }
    }
    toyManualsStorageAccount: {
      sku: {
        name: 'Standard_ZRS'
      }
    }
    toykeyvault: {
      objectid: '910c059e-d5a9-4d8d-9146-b11918fda356'
      sku: {
        name: 'premium'
        family: 'A'
      }
    }
  }
}

@description('The type of environment. This must be Test or Production.')
@allowed([
  'Test'
  'Production'
])
param environmentType string

// ============ main.bicep ============

module keyvault 'modules/keyvault.bicep' ={
  name: 'toy-keyvault-name'
  params: {
    location: location
    sku: environmentConfigurationMap[environmentType].toykeyvault.sku
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    keyVaultName: keyVaultName
    objectId: environmentConfigurationMap[environmentType].toykeyvault.objectId
  }
}

// module db 'modules/sql.bicep' = {
//   name: 'sqlDbDeployment1'
//   scope: rg
//   params: {
//     myPassword: keyVault.getSecret('mySqlPassword')
//     location: rg.location
//     // myPassword: keyVault.getSecret('mySqlPassword', '2cc1676124b77bc9a1bfd30d8f4b6225')
//   }
// }

module app 'modules/app.bicep' ={
name: 'toy-launch-name'
  params: {
    appServiceAppName: appServiceAppName
    appServicePlanName: appServicePlanName
    location: location
    environmentSku: environmentConfigurationMap[environmentType].appServicePlan.sku
  }
}

module storage 'modules/storage.bicep' = {
  name: 'test-storage-account'
  params: {
    location: location
    storageAccountName: storageaccountName
    environmentSku: environmentConfigurationMap[environmentType].toyManualsStorageAccount.sku
  }
}


@description('The host name to use to access the website.')
output websiteHostName string = app.outputs.appServiceAppHostName
