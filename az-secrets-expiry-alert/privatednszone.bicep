param privateStorageFileDnsZoneName string
param privateStorageBlobDnsZoneName string
param privateStorageTableDnsZoneName string
param privateStorageQueueDnsZoneName string
param privatelogicappdnszoneName string
param privatekeyvaultdnszoneName string

resource privateStorageFileDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageFileDnsZoneName
  location: 'global'
}

resource privateStorageBlobDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageBlobDnsZoneName
  location: 'global'
}

resource privateStorageTableDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageTableDnsZoneName
  location: 'global'
}

resource privateStorageQueueDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageQueueDnsZoneName
  location: 'global'
}

resource privatelogicappdnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privatelogicappdnszoneName
  location: 'global'
}

resource privatekeyvaultdnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privatekeyvaultdnszoneName
  location: 'global'
}

output privatestorageFileDnsZone_id string = privateStorageFileDnsZone.id
output privateStorageBlobDnsZone_id string = privateStorageBlobDnsZone.id
output privateStorageTableDnsZone_id string = privateStorageTableDnsZone.id
output privateStorageQueueDnsZone_id string = privateStorageQueueDnsZone.id
output privatelogicappdnszone_id string = privatelogicappdnszone.id
output privatekeyvaultdnszone_id string = privatekeyvaultdnszone.id
