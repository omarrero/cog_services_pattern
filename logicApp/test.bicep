param subscriptionId string
param name string
param location string
param use32BitWorkerProcess bool
param ftpsState string
param storageAccountName string
param netFrameworkVersion string
param sku string
param skuCode string
param workerSize string
param workerSizeId string
param numberOfWorkers string
param hostingPlanName string
param serverFarmResourceGroup string
param alwaysOn bool

resource name_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: name
  kind: 'functionapp,workflowapp'
  location: location
  tags: {
    'hidden-link: /app-insights-resource-id': '/subscriptions/b734d887-20b3-4c8a-bdaa-70ac9da657db/resourceGroups/rg-ntsprint-dev-eus2/providers/Microsoft.Insights/components/pdfHandlerWorkflow'
  }
  properties: {
    name: name
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: reference('microsoft.insights/components/pdfHandlerWorkflow', '2015-05-01').ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId('b734d887-20b3-4c8a-bdaa-70ac9da657db', 'rg-ntsprint-dev-eus2', 'Microsoft.Storage/storageAccounts', storageAccountName), '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId('b734d887-20b3-4c8a-bdaa-70ac9da657db', 'rg-ntsprint-dev-eus2', 'Microsoft.Storage/storageAccounts', storageAccountName), '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: 'pdfhandlerworkflow92c7'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
      ]
      cors: {}
      use32BitWorkerProcess: use32BitWorkerProcess
      ftpsState: ftpsState
      netFrameworkVersion: netFrameworkVersion
    }
    clientAffinityEnabled: false
    virtualNetworkSubnetId: null
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
    serverFarmId: '/subscriptions/${subscriptionId}/resourcegroups/${serverFarmResourceGroup}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    pdfHandlerWorkflow
    hostingPlan
  ]
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  kind: ''
  tags: {}
  properties: {
    name: hostingPlanName
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
    maximumElasticWorkerCount: 20
    zoneRedundant: false
  }
  sku: {
    tier: sku
    name: skuCode
  }
  dependsOn: []
}

resource pdfHandlerWorkflow 'microsoft.insights/components@2020-02-02-preview' = {
  name: 'pdfHandlerWorkflow'
  location: location
  tags: {}
  properties: {
    ApplicationId: name
    Request_Source: 'IbizaWebAppExtensionCreate'
    Flow_Type: 'Redfield'
    Application_Type: 'web'
    WorkspaceResourceId: '/subscriptions/${subscriptionId}/resourceGroups/DefaultResourceGroup-EUS2/providers/Microsoft.OperationalInsights/workspaces/DefaultWorkspace-b734d887-20b3-4c8a-bdaa-70ac9da657db-EUS2'
  }
  dependsOn: [
    newWorkspaceTemplate
  ]
}

module newWorkspaceTemplate './nested_newWorkspaceTemplate.bicep' = {
  name: 'newWorkspaceTemplate'
  scope: resourceGroup(subscriptionId, 'DefaultResourceGroup-EUS2')
  params: {}
}
