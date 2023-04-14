// ============ sqldb.bicep ============

@secure()
param myPassword string

param location string

resource sqlserver 'Microsoft.Sql/servers@2022-08-01-preview' = {
  name: 'ContosoSqlServer'
  location: location
  properties: {
    administratorLogin: 'alcesadmin'
    administratorLoginPassword: myPassword
  }

  resource sqldb 'databases' = {
    name: 'contosodb'
    location: location
  }
}
