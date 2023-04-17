// ============ sqldb.bicep ============

@secure()
param myPassword string

param location string

param sku object

param administratorLogin string

param mysqlVersion string

param SkuSizeMB int

param backupRetentionDays int

param geoRedundantBackup string

param subnetId string

param sqlServerName string

param virtualNetworkRuleName string

var firewallrules = [
  {
    Name: 'rule1'
    StartIpAddress: '0.0.0.0'
    EndIpAddress: '255.255.255.255'
  }
  {
    Name: 'rule2'
    StartIpAddress: '0.0.0.0'
    EndIpAddress: '255.255.255.255'
  }
]
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

resource mysqlDbServer 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  name: sqlServerName
  location: location
  sku : sku
  properties: {
    createMode: 'Default'
    version: mysqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: myPassword
    storageProfile: {
      storageMB: SkuSizeMB
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }

  resource virtualNetworkRule 'virtualNetworkRules@2017-12-01' = {
    name: virtualNetworkRuleName
    properties: {
      virtualNetworkSubnetId: subnetId
      ignoreMissingVnetServiceEndpoint: true
    }
  }
}

@batchSize(1)
resource firewallRules 'Microsoft.DBforMySQL/servers/firewallRules@2017-12-01' = [for rule in firewallrules: {
  parent: mysqlDbServer
  name: '${rule.Name}'
  properties: {
    startIpAddress: rule.StartIpAddress
    endIpAddress: rule.EndIpAddress
  }
}]
