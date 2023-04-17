@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the App Service app.')
param appServiceAppName string = 'toy-${uniqueString(resourceGroup().id)}'

@description('The name of the App Service app.')
@minLength(3)
@maxLength(24)
param storageaccountName string = 'test${uniqueString(resourceGroup().id)}'


var appServicePlanName = 'toy-product-launch-plan'

var serviceBusNamespaceName = 'toy-service-bus'

var serviceBusQueueName = 'toy-queue'

param SQLSkuSizeMB int = 5120

@description('MySQL version')
@allowed([
  '5.6'
  '5.7'
  '8.0'
])
param mysqlVersion string = '8.0'

@description('Virtual Network Name')
param virtualNetworkName string = 'azure_mysql_vnet'

@description('Subnet Name')
param subnetName string = 'azure_mysql_subnet'

@description('Virtual Network RuleName')
param virtualNetworkRuleName string = 'AllowSubnet'

@description('Virtual Network Address Prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet Address Prefix')
param subnetPrefix string = '10.0.0.0/16'

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
    servicebus: {
      sku: {
        name: 'Standard'
      }
    }
    mysqldatabase: {
      sku: {
        name: 'GP_Gen5_2' //skuName
        tier: 'GeneralPurpose' //SkuTier - GeneralPurpose, Basic, MemoryoPTIMIZED
        capacity: 2 //skuCapacity
        size: '${SQLSkuSizeMB}'  //size in mb - a string is expected here but a int for the storageProfile...
        family: 'Gen5' //skuFamily
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
    servicebus: {
      sku: {
        name: 'Standard'
      }
    }
    mysqldatabase: {
      sku: {
        name: 'GP_Gen5_2' //skuName
        tier: 'GeneralPurpose' //SkuTier - GeneralPurpose, Basic, MemoryoPTIMIZED
        capacity: 2 //skuCapacity
        size: '${5120}'  //size in mb - a string is expected here but a int for the storageProfile...
        family: 'Gen5' //skuFamily
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
//First create the keyvault for passwords, put them there, then uncomment the other stuff
// module kv 'modules/keyvault.bicep' ={
//   name: 'toy-keyvault-name'
//   params: {
//     location: location
//     sku: environmentConfigurationMap[environmentType].toykeyvault.sku
//     enabledForDeployment: true
//     enabledForDiskEncryption: true
//     enabledForTemplateDeployment: true
//     keyVaultName: keyVaultName
//     objectId: environmentConfigurationMap[environmentType].toykeyvault.objectId
//   }
// }
resource kvRef 'Microsoft.KeyVault/vaults@2023-02-01' existing = {     
  name: keyVaultName     
  //scope: resourceGroup(subscription().id, resourceGroup().id )
}   

// module db 'modules/sql.bicep' = {
//   name: 'sqlDbDeployment1'
//   params: {
//     myPassword: kvRef.getSecret('mySqlPassword')
//     location: location
//   }
// }

// module db 'modules/sql.bicep' ={
//   name: 'sqldeployment'
//   params: {
//     location: location
//     myPassword: kvRef.getSecret('mySqlPassword')
//     sku: environmentConfigurationMap[environmentType].mysqldatabase.sku
//   }
// }

module networking 'modules/network.bicep' ={
  name: 'networkingRules'
  params: {
    location: location
    subnetName: subnetName
    subnetPrefix: subnetPrefix
    virtualNetworkName: virtualNetworkName
    vnetAddressPrefix: vnetAddressPrefix
  }
}

module db 'modules/sql.bicep' ={
  name: 'sqlDeployment'
  params: {
    administratorLogin: 'alcesitadmin' 
    backupRetentionDays: 7
    geoRedundantBackup: 'Disabled'
    location: location
    myPassword: kvRef.getSecret('mySqlPassword')
    mysqlVersion: mysqlVersion
    sku: environmentConfigurationMap[environmentType].mysqldatabase.sku
    SkuSizeMB: SQLSkuSizeMB
    sqlServerName: 'sqltestserver'
    subnetId: resourceId('virtualNetworks/subnet', subnetName) 
    virtualNetworkRuleName: virtualNetworkRuleName
  }
}

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

module servicebus 'modules/servicebus.bicep' ={
  name: 'test-service-bus'
  params: {
    location: location
    serviceBusNamespaceName: serviceBusNamespaceName
    serviceBusQueueName: serviceBusQueueName
    sku: environmentConfigurationMap[environmentType].servicebus.sku
  }
}


@description('The host name to use to access the website.')
output websiteHostName string = app.outputs.appServiceAppHostName
