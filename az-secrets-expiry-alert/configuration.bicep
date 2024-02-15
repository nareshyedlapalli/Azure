@description('Environment name')
@allowed([
  'prd'
  'dev'
])
param env string

var environmentConfigurationMap = {
  dev: {
    privateEndpointVnet: {// Private endpoint VNet settings
      resoureGroupName: 'iw-vnet-eastus2'
      virtualNetworkName: 'iw-vnet-eastus2-6a0bd5a4-9826-44fa-9023-813f69860137'
      subnetName: 'snet-corp-development-01-privateendpoint-eastus2-01'
    }
    emailReceiver: 'amit.yadav@inchworks.net'
  }
  prd: {
    privateEndpointVnet: {// Private endpoint VNet settings
      resoureGroupName: 'iw-vnet-eastus2'
      virtualNetworkName: 'iw-vnet-eastus2-6a0bd5a4-9826-44fa-9023-813f69860137'
      subnetName: 'snet-corp-development-01-privateendpoint-eastus2-01'
      emailReceiver: 'amit.yadav@inchworks.net'
    }
  }
}

output settings object = environmentConfigurationMap[env]
