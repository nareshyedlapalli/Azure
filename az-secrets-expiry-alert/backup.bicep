param logicAppFEname string = 'logicapphdgghfgh01'
param fileShareName string = 'fileshare'
param appInsightName string = 'logicapphdgghfgh01'
param use32BitWorkerProcess bool = false
param privateDNSzoneRG string = 'iw-vnet-eastus2'

@description('Location to deploy resources to.')
param location string = resourceGroup().location
param hostingPlanFEName string = 'asplogic010101'
param contentStorageAccountName string = 'fileshare1010199'
// param sku string = 'WorkflowStandard'
// param skuCode string = 'WS1'
param workerSize string = '1'
param workerSizeId string = '1'
param numberOfWorkers string = '1'

@description('Name of the VNET that the Function App and Storage account will communicate over.')
param vnetName string = 'VirtualNetwork'
param subnetName string = 'mysubnet'

@description('VNET address space.')
param virtualNetworkAddressPrefix string = '10.100.0.0/16'

@description('Function App\'s subnet address range.')
param functionSubnetAddressPrefix string = '10.100.0.0/24'

@description('Storage account\'s private endpoint\'s subnet address range.')
param privateEndpointSubnetAddressPrefix string = '10.100.1.0/24'

var privateStorageFileDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'
var privateStorageBlobDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var privateStorageQueueDnsZoneName = 'privatelink.queue.${environment().suffixes.storage}'
var privateStorageTableDnsZoneName = 'privatelink.table.${environment().suffixes.storage}'
var privateLogicAppDnsZoneName = 'privatelink.azurewebsites.net'
var privateEndpointFileStorageName = '${contentStorageAccountName}-file-private-endpoint'
var privateEndpointBlobStorageName = '${contentStorageAccountName}-blob-private-endpoint'
var privateEndpointQueueStorageName = '${contentStorageAccountName}-queue-private-endpoint'
var privateEndpointTableStorageName = '${contentStorageAccountName}-table-private-endpoint'
var privateEndpointLogicAppName = '${logicAppFEname}-private-endpoint'
var virtualNetworkLinksSuffixFileStorageName = '${privateStorageFileDnsZoneName}-link'
var virtualNetworkLinksSuffixBlobStorageName = '${privateStorageBlobDnsZoneName}-link'
var virtualNetworkLinksSuffixQueueStorageName = '${privateStorageQueueDnsZoneName}-link'
var virtualNetworkLinksSuffixTableStorageName = '${privateStorageTableDnsZoneName}-link'
var virtualNetworkLinksSuffixLogicAppName = '${privateLogicAppDnsZoneName}-link'

resource vnet 'Microsoft.Network/virtualNetworks@2020-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: functionSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'webapp'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
                actions: [
                  'Microsoft.Network/virtualNetworks/subnets/action'
                ]
              }
            }
          ]
        }
      }
      {
        name: contentStorageAccountName
        properties: {
          addressPrefix: privateEndpointSubnetAddressPrefix
          privateLinkServiceNetworkPolicies: 'Enabled'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource contentStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: contentStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
  dependsOn: [
    vnet
  ]
}

resource contentStorageAccountName_default_fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  name: '${contentStorageAccountName}/default/${toLower(fileShareName)}'
  
  dependsOn: [
    contentStorageAccount
  ]
}

resource privateStorageFileDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageFileDnsZoneName
  location: 'global'
  dependsOn: [
    vnet
  ]
}

resource privateStorageBlobDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageBlobDnsZoneName
  location: 'global'
  dependsOn: [
    vnet
  ]
}

resource privateStorageQueueDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageQueueDnsZoneName
  location: 'global'
  dependsOn: [
    vnet
  ]
}

resource privateStorageTableDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageTableDnsZoneName
  location: 'global'
  dependsOn: [
    vnet
  ]
}


resource privateStorageFileDnsZoneName_virtualNetworkLinksSuffixFileStorage 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateStorageFileDnsZone
  name: '${virtualNetworkLinksSuffixFileStorageName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateStorageBlobDnsZoneName_virtualNetworkLinksSuffixBlobStorage 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateStorageBlobDnsZone
  name: '${virtualNetworkLinksSuffixBlobStorageName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateStorageQueueDnsZoneName_virtualNetworkLinksSuffixQueueStorage 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateStorageQueueDnsZone
  name: '${virtualNetworkLinksSuffixQueueStorageName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateStorageTableDnsZoneName_virtualNetworkLinksSuffixTableStorage 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateStorageTableDnsZone
  name: '${virtualNetworkLinksSuffixTableStorageName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateEndpointFileStorage 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointFileStorageName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, contentStorageAccountName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: contentStorageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
  dependsOn: [
    contentStorageAccountName_default_fileShare
    vnet
  ]
}

resource privateEndpointBlobStorage 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointBlobStorageName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, contentStorageAccountName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: contentStorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
  dependsOn: [
    contentStorageAccountName_default_fileShare
    vnet
  ]
}

resource privateEndpointQueueStorage 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointQueueStorageName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, contentStorageAccountName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: contentStorageAccount.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
  dependsOn: [
    contentStorageAccountName_default_fileShare
    vnet
  ]
}

resource privateEndpointTableStorage 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointTableStorageName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, contentStorageAccountName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: contentStorageAccount.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
  dependsOn: [
    contentStorageAccountName_default_fileShare
    vnet
  ]
}

resource privateEndpointFileStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointFileStorage
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: 'privateStorageFileDnsZone.id'
        }
      }
    ]
  }
}

resource privateEndpointBlobStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointBlobStorage
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageBlobDnsZone.id
        }
      }
    ]
  }
}

resource privateEndpointQueueStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointQueueStorage
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageQueueDnsZone.id
        }
      }
    ]
  }
}

resource privateEndpointTableStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointTableStorage
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageTableDnsZone.id
        }
      }
    ]
  }
}


resource Microsoft_Web_sites_logicAppFEname 'Microsoft.Web/sites@2018-11-01' = {
  name: logicAppFEname
  location: location
  tags: {}
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    name: logicAppFEname
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(resourceId('Microsoft.Insights/components', appInsightName), '2015-05-01').InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: reference(resourceId('Microsoft.Insights/components', appInsightName), '2015-05-01').ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${contentStorageAccountName};AccountKey=${listKeys(contentStorageAccount.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${contentStorageAccountName};AccountKey=${listKeys(contentStorageAccount.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(fileShareName)
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
          slotSetting: false
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
          slotSetting: false
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
          slotSetting: false
        }
      ]
      use32BitWorkerProcess: use32BitWorkerProcess
      cors: {
        allowedOrigins: [
          'https://afd.hosting.portal.azure.net'
          'https://afd.hosting-ms.portal.azure.net'
          'https://hosting.portal.azure.net'
          'https://ms.hosting.portal.azure.net'
          'https://ema-ms.hosting.portal.azure.net'
          'https://ema.hosting.portal.azure.net'
          'https://ema.hosting.portal.azure.net'
        ]
      }
    }
    serverFarmId: hostingPlanFE.id
    clientAffinityEnabled: true
  }
}

resource logicAppFEname_virtualNetwork 'Microsoft.Web/sites/networkconfig@2018-11-01' = {
  parent: Microsoft_Web_sites_logicAppFEname
  name: 'virtualNetwork'
  location: location
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    swiftSupported: true
  }
  dependsOn: [
    logicAppFEname_resource
  ]
}


resource hostingPlanFE 'Microsoft.Web/serverfarms@2018-11-01' = {
  name: hostingPlanFEName
  location: location
  tags: {}
  sku: {
    tier: 'WorkflowStandard'
    name: 'WS1'
  }
  kind: ''
  properties: {
    name: hostingPlanFEName
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
    maximumElasticWorkerCount: '20'
  }
  dependsOn: []
}

resource privateLogicAppDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateLogicAppDnsZoneName
  location: 'global'
  dependsOn: [
    vnet
  ]
}

resource privateLogicAppDnsZoneName_virtualNetworkLinksSuffixLogicApp 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateLogicAppDnsZone
  name: '${virtualNetworkLinksSuffixLogicAppName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateEndpointLogicApp 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointLogicAppName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, contentStorageAccountName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyLogicAppPrivateLinkConnection'
        properties: {
          privateLinkServiceId: Microsoft_Web_sites_logicAppFEname.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
  dependsOn: [
    Microsoft_Web_sites_logicAppFEname
    vnet
  ]
}

resource privateEndpointLogicAppName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointLogicApp
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateLogicAppDnsZone.id
        }
      }
    ]
  }
}

resource logicAppFEname_resource 'Microsoft.Insights/components@2020-02-02' = {
  name: logicAppFEname
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

