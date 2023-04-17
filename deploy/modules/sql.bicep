// ============ sqldb.bicep ============
//TODO cleanup, move parameter to a file

@secure()
param administratorLoginPassword string

param location string

param sku object

param administratorLogin string

param backupRetentionDays int

@allowed([
  'Disabled'
  'Enabled'
])
param geoRedundantBackup string

// resource sqlserver 'Microsoft.Sql/servers@2022-08-01-preview' = {
//   name: 'ContosoSqlServer'
//   location: location
//   properties: {
//     administratorLogin: 'alcesadmin'
//     administratorLoginPassword: myPassword
//   }

//   resource sqldb 'databases' = {
//     name: 'contosodb'
//     location: location
//   }

// resource mysqlDbServer 'Microsoft.DBforMySQL/servers@2017-12-01' = {
//   name: sqlServerName
//   location: location
//   sku : sku
//   properties: {
//     createMode: 'Default'
//     version: mysqlVersion
//     administratorLogin: administratorLogin
//     administratorLoginPassword: administratorLoginPassword
//     storageProfile: {
//       storageMB: SkuSizeMB
//       backupRetentionDays: backupRetentionDays
//       geoRedundantBackup: geoRedundantBackup
//     }
//   }

//   resource virtualNetworkRule 'virtualNetworkRules@2017-12-01' = {
//     name: virtualNetworkRuleName
//     properties: {
//       virtualNetworkSubnetId: subnetId
//       ignoreMissingVnetServiceEndpoint: true
//     }
//   }
// }

@description('Provide a prefix for creating resource names.')
param resourceNamePrefix string




@description('Server version')
@allowed([
  '5.7'
  '8.0.21'
])
param version string = '8.0.21'

@description('Availability Zone information of the server. (Leave blank for No Preference).')
param availabilityZone string = '1'

@description('High availability mode for a server : Disabled, SameZone, or ZoneRedundant')
@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
param haEnabled string = 'Disabled'

@description('Availability zone of the standby server.')
param standbyAvailabilityZone string = '2'

param storageSizeGB int = 20
param storageIops int = 360
@allowed([
  'Enabled'
  'Disabled'
])
param storageAutogrow string = 'Enabled'


param serverName string = '${resourceNamePrefix}sqlserver'
param databaseName string = '${resourceNamePrefix}mysqldb'

resource server 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  location: location
  name: serverName
  sku : sku
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    availabilityZone: availabilityZone
    highAvailability: {
      mode: haEnabled
      standbyAvailabilityZone: standbyAvailabilityZone
    }
    storage: {
      storageSizeGB: storageSizeGB
      iops: storageIops
      autoGrow: storageAutogrow
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }
}

resource database 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: server
  name: databaseName
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}
