param location string
param storage_name string
param subnetid string
param privatefilednszone string
param privateblobdnszone string
param privatetablednszone string
param privatequeuednszone string
param filesharename string

resource storage_name_resource 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storage_name
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    // networkAcls: {
    //   bypass: 'AzureServices'
    //   defaultAction: 'Deny'
    // }
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
}

resource contentStorageAccountName_default_fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  name: '${storage_name}/default/${toLower(filesharename)}'
  
  dependsOn: [
    storage_name_resource
  ]
}


resource blobprivateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${storage_name}-blob-pep'
  location: location
  properties: {
    subnet: {
      id: subnetid
    }
    privateLinkServiceConnections: [
      {
        name: '${storage_name}-blob-pep'
        properties: {
          privateLinkServiceId: storage_name_resource.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource fileprivateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${storage_name}-file-pep'
  location: location
  properties: {
    subnet: {
      id: subnetid
    }
    privateLinkServiceConnections: [
      {
        name: '${storage_name}-file-pep'
        properties: {
          privateLinkServiceId: storage_name_resource.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource tableprivateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${storage_name}-table-pep'
  location: location
  properties: {
    subnet: {
      id: subnetid
    }
    privateLinkServiceConnections: [
      {
        name: '${storage_name}-table-pep'
        properties: {
          privateLinkServiceId: storage_name_resource.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

resource queueprivateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${storage_name}-queue-pep'
  location: location
  properties: {
    subnet: {
      id: subnetid
    }
    privateLinkServiceConnections: [
      {
        name: '${storage_name}-queue-pep'
        properties: {
          privateLinkServiceId: storage_name_resource.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
}

resource privateEndpointFileStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: fileprivateEndpoint
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privatefilednszone
        }
      }
    ]
  }
}

resource privateEndpointblobStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: blobprivateEndpoint
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateblobdnszone
        }
      }
    ]
  }
}

resource privateEndpointtableStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: tableprivateEndpoint
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privatetablednszone
        }
      }
    ]
  }
}

resource privateEndpointqueueStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: queueprivateEndpoint
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privatequeuednszone
        }
      }
    ]
  }
}

output storage_name_resource_id string = storage_name_resource.id
