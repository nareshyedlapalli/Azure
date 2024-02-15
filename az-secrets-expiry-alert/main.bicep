param connections_keyvault_name string = 'keyvault'
param connections_office365_name string = 'office365'
param keyvaultname string = 'keyvaultsecretalertspo19'
param logic_app_name string = 'azure-app-notification18'
param storage_name string = 'azsecretsexpiryaler18'
param serverfarms_name string = 'aspforlogicapp18'
param appInsightName string = 'logicappai18'
param logicAppFEname string = 'logicappai18'
param privateDNSzoneRG string = 'iw-vnet-eastus2'
param filesharename string = 'logicappdata'
param vnetIntegrationsubnetId string = '/subscriptions/6a0bd5a4-9826-44fa-9023-813f69860137/resourceGroups/iw-vnet-eastus2/providers/Microsoft.Network/virtualNetworks/iw-vnet-eastus2-6a0bd5a4-9826-44fa-9023-813f69860137/subnets/snet-corp-development-01-appservice-eastus2-01'
param location string = 'eastus2'
param tenantId string
param ClientId string
@secure()
param ClientSecret string
param env string
var privateStorageFileDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'
var privateStorageBlobDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var privateStorageQueueDnsZoneName = 'privatelink.queue.${environment().suffixes.storage}'
var privateStorageTableDnsZoneName = 'privatelink.table.${environment().suffixes.storage}'
var privatekeyvaultdnszoneName = 'privatelink.vaultcore.azure.net'
var privateLogicAppDnsZoneName = 'privatelink.azurewebsites.net'

@description('A module that defines all the environment specific configuration')
module configModule './configuration.bicep' = {
  name: '${resourceGroup().name}-config-module'
  scope: resourceGroup()
  params: {
    env: env
  }
}

@description('A variable to hold all environment specific variables')
var config = configModule.outputs.settings

@description('Obtaining reference to the virtual network subnet for the private endpoint')
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  name: '${config.privateEndpointVnet.virtualNetworkName}/${config.privateEndpointVnet.subnetName}'
  scope: resourceGroup(config.privateEndpointVnet.resoureGroupName)
}

module privatednszone './privatednszone.bicep' = {
  name: privateStorageFileDnsZoneName
  scope: resourceGroup(privateDNSzoneRG)
  params:{
    privateStorageFileDnsZoneName:privateStorageFileDnsZoneName
    privateStorageBlobDnsZoneName:privateStorageBlobDnsZoneName
    privateStorageTableDnsZoneName:privateStorageTableDnsZoneName
    privateStorageQueueDnsZoneName:privateStorageQueueDnsZoneName
    privatelogicappdnszoneName:privateLogicAppDnsZoneName
    privatekeyvaultdnszoneName:privatekeyvaultdnszoneName
  }
}

@description('Module to create data collections related resources')
module connection_name_resource './connections.bicep' = {
  name: 'connections'
  params: {
    location: location
    connections_keyvault_name: connections_keyvault_name
    connections_office365_name: connections_office365_name
    keyvaultname: keyvaultname
    logicAppSystemAssignedIdentityTenantId: tenantId
    logicAppSystemAssignedIdentityObjectId: logic_app_name_resource.outputs.logicappid
  }
}

@description('Module to create data collections related resources')
module keyvaultname_resource './keyvault.bicep' = {
  name: keyvaultname
  params: {
    location: location
    keyvaultname: keyvaultname
    tenantId: tenantId
    ClientId: ClientId
    ClientSecret: ClientSecret
    subnetid:subnet.id
    logicappid: logic_app_name_resource.outputs.logicappid
    privatekeyvaultdnszone:privatednszone.outputs.privatekeyvaultdnszone_id
  }
}

@description('Module to create data collections related resources')
module storage_name_resource './storageaccount.bicep' = {
  name: storage_name
  params: {
    location: location
    storage_name: storage_name
    subnetid:subnet.id
    filesharename:filesharename
    privatefilednszone:privatednszone.outputs.privatestorageFileDnsZone_id
    privateblobdnszone:privatednszone.outputs.privateStorageBlobDnsZone_id
    privatetablednszone:privatednszone.outputs.privateStorageTableDnsZone_id
    privatequeuednszone:privatednszone.outputs.privateStorageQueueDnsZone_id
  }
}

@description('Module to create data collections related resources')
module logic_app_name_resource './logicapp.bicep' = {
  name: logic_app_name
  params: {
    location: location
    logic_app_name: logic_app_name
    storage_name: storage_name
    appInsightName:appInsightName
    logicAppFEname:logicAppFEname
    filesharename:filesharename
    vnetIntegrationsubnetId:vnetIntegrationsubnetId
    subnetid:subnet.id
    storage_name_resource_id:storage_name_resource.outputs.storage_name_resource_id
    privatelogicappdnszone:privatednszone.outputs.privatelogicappdnszone_id
    serverfarms_name:serverfarms_name
    keyvaultname:keyvaultname
}
dependsOn:[
  storage_name_resource
  privatednszone
]
}
