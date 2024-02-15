param keyvaultname string
param location string
param tenantId string
param ClientId string
@secure()
param ClientSecret string
param subnetid string
param logicappid string
param privatekeyvaultdnszone string

resource keyvaultname_resource 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyvaultname
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: logicappid
        tenantId: subscription().tenantId
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
        }
      }
      {
        objectId: '28685f0a-428d-4970-a79c-a4ca2db25363'
        tenantId: subscription().tenantId
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
        }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
    vaultUri: 'https://${keyvaultname}.vault.azure.net/'
    provisioningState: 'Succeeded'
    publicNetworkAccess: 'Disabled'
  }
}

resource keyvaultname_tenant_id 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyvaultname_resource
  name: 'tenant-id'
  properties: {
    value: tenantId
    attributes: {
      enabled: true
    }
  }
}

resource keyvaultname_client_id 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyvaultname_resource
  name: 'client-id'
  properties: {
    value: ClientId
    attributes: {
      enabled: true
    }
  }
}

resource keyvaultname_client_secret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyvaultname_resource
  name: 'client-secret'
  properties: {
    value: ClientSecret
    attributes: {
      enabled: true
    }
  }
}

resource keyvaultprivateendpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = {
  name: '${keyvaultname}-pep'
  location: location
  properties: {
    subnet: {
      id: subnetid
    }
    privateLinkServiceConnections: [
      {
        name: 'peconnection-kv'
        properties: {
          privateLinkServiceId: keyvaultname_resource.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource privateEndpointqueueStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: keyvaultprivateendpoint
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privatekeyvaultdnszone
        }
      }
    ]
  }
}

output keyvaultname_resource_id string = keyvaultname_resource.id
