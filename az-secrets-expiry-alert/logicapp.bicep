param location string
param logic_app_name string
param storage_name string
param serverfarms_name string
param storage_name_resource_id string
param vnetIntegrationsubnetId string
param subnetid string
param privatelogicappdnszone string
param appInsightName string
param filesharename string
param workerSize string = '1'
param workerSizeId string = '1'
param numberOfWorkers string = '1'
param logicAppFEname string
param keyvaultname string

// App service containing the workflow runtime
resource logic_app_name_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: logic_app_name
  location: location
  tags: {}
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    name: logic_app_name
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
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage_name};AccountKey=${listKeys(storage_name_resource_id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage_name};AccountKey=${listKeys(storage_name_resource_id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(filesharename)
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
        {
          name: 'keyVault_VaultUri'
          value: 'https://${keyvaultname}.vault.azure.net/'
        }
      ]
      use32BitWorkerProcess: true
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
  parent: logic_app_name_resource
  name: 'virtualNetwork'
  location: location
  properties: {
    subnetResourceId: vnetIntegrationsubnetId
    swiftSupported: true
  }
  dependsOn: [
    logicAppFEname_resource
  ]
}


resource hostingPlanFE 'Microsoft.Web/serverfarms@2018-11-01' = {
  name: serverfarms_name
  location: location
  tags: {}
  sku: {
    tier: 'WorkflowStandard'
    name: 'WS1'
  }
  kind: ''
  properties: {
    name: serverfarms_name
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
    maximumElasticWorkerCount: '20'
  }
  dependsOn: []
}


resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${logic_app_name}-pep'
  location: location
  properties: {
    subnet: {
      id: subnetid
    }
    privateLinkServiceConnections: [
      {
        name: '${logic_app_name}-plconnection'
        properties: {
          privateLinkServiceId: logic_app_name_resource.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateEndpointqueueStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpoint
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privatelogicappdnszone
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

output logicappid string = logic_app_name_resource.identity.principalId
