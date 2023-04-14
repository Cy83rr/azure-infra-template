//targetScope = 'subscription'

// @description('Name of the resource group')
// param resourceGroupName string = 'TESTCLOUDWESTUS3'

@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the App Service app.')
param appServiceAppName string = 'toy-${uniqueString(resourceGroup().id)}'

@description('The name of the App Service app.')
@minLength(3)
@maxLength(24)
param storageaccountName string = 'test${uniqueString(resourceGroup().id)}'


var appServicePlanName = 'toy-product-launch-plan'

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
  }
}

@description('The type of environment. This must be Test or Production.')
@allowed([
  'Test'
  'Production'
])
param environmentType string

// resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
//   name: resourceGroupName
//   location: location
// }

// ============ main.bicep ============

// resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
//   name: 'kv-contoso'
//   scope: rg
//   // scope: resourceGroup('rg-contoso')   - if key vault is in a different resource group
// }

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
