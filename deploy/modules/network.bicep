@description('Virtual Network Name')
param virtualNetworkName string

@description('Subnet Name')
param subnetName string

@description('Virtual Network Address Prefix')
param vnetAddressPrefix string

@description('Subnet Address Prefix')
param subnetPrefix string

param location string

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnetPrefix
  }
}

