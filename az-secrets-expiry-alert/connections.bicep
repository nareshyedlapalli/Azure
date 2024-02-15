param connections_keyvault_name string
param connections_office365_name string
param location string
param keyvaultname string
param logicAppSystemAssignedIdentityTenantId string
param logicAppSystemAssignedIdentityObjectId string

resource connections_keyvault_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_keyvault_name
  location: location
  kind: 'V2'
  properties: {
    api: {
      id: 'subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/keyvault'
    }
    displayName: connections_keyvault_name
    parameterValues: {
      vaultName: keyvaultname
    }
  }
}

resource connections_office365_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_office365_name
  location: location
  kind: 'V2'
  properties: {
    displayName: 'amit.yadav@inchworks.net'
    statuses: [
      {
        status: 'Connected'
      }
    ]
    customParameterValues: {}
    nonSecretParameterValues: {}
    createdTime: '2023-06-08T17:06:38.6130764Z'
    changedTime: '2023-06-18T14:39:03.7226522Z'
    api: {
      name: connections_office365_name
      displayName: 'Office 365 Outlook'
      description: 'Microsoft Office 365 is a cloud-based service that is designed to help meet your organization\'s needs for robust security, reliability, and user productivity.'
      iconUri: 'https://connectoricons-prod.azureedge.net/u/shgogna/globalperconnector-train1/1.0.1639.3313/${connections_office365_name}/icon.png'
      brandColor: '#0078D4'
      id: '/subscriptions/6a0bd5a4-9826-44fa-9023-813f69860137/providers/Microsoft.Web/locations/eastus2/managedApis/${connections_office365_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: [
      {
        requestUri: 'https://management.azure.com:443/subscriptions/6a0bd5a4-9826-44fa-9023-813f69860137/resourceGroups/rg-vm-dev-eastus2-01/providers/Microsoft.Web/connections/${connections_office365_name}/extensions/proxy/testconnection?api-version=2016-06-01'
        method: 'get'
      }
    ]
  }
}

resource connections_keyvault_name_logicAppSystemAssignedIdentityObjectId 'Microsoft.Web/connections/accessPolicies@2016-06-01' = {
  name: '${connections_keyvault_name_resource.name}/${logicAppSystemAssignedIdentityObjectId}'
  location: location
  properties: {
    principal: {
      type: 'ActiveDirectory'
      identity: {
        tenantId: logicAppSystemAssignedIdentityTenantId
        objectId: logicAppSystemAssignedIdentityObjectId
      }
    }
  }
}

output keyvaultconnectionId string = connections_keyvault_name_resource.id
output office365connectionId string = connections_office365_name_resource.id
