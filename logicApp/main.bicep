param location string
param databaseName string
param containerName string
param secondaryRegion string
param formRecognizerKey string
param formRecognizerEndpoint string
param dataLakeStoreAccountName string
param cosmosDbAccountName string
param cosmosDbDatabaseThroughput int
param cosmosDbContainerThroughput int
param cosmosDbContainerName string

resource dataLakeStoreAccount 'Microsoft.DataLakeStore/accounts@2016-11-01' = {
  name: dataLakeStoreAccountName
  location: location
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: uniqueString('st', resourceGroup().id)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageAccount.name}/default/myContainer'
  dependsOn: [
    storageAccount
  ]
}

resource formRecognizerAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: uniqueString('fr', resourceGroup().id)
  location: location
  kind: 'CognitiveServices'
  sku: {
    name: 'S0'
  }
}

resource formRecognizerConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'formRecognizerConnection'
  location: location
  properties: {
    displayName: 'Form Recognizer Connection'
    api: {
      id: formRecognizerAccount.id
      displayName: 'Form Recognizer'
    }
    parameterValues: {
      endpoint: formRecognizerEndpoint
      subscriptionKey: formRecognizerKey
    }
  }
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-09-15' = {
  name: cosmosDbAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
      {
        locationName: secondaryRegion
        failoverPriority: 1
      }
    ]
  }
}

resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-09-15' = {
  name: 'default/myDatabase'
  dependsOn: [
    cosmosDbAccount
  ]
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: cosmosDbDatabaseThroughput
    }
  }
}

resource cosmosDbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-09-15' = {
  name: '${cosmosDbAccount.name}/default/myContainer'
  dependsOn: [
    cosmosDbDatabase
  ]
  properties: {
    resource: {
      id: cosmosDbContainerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
    }
    options: {
      throughput: cosmosDbContainerThroughput
    }
  }
}

resource logicAppWorkflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'pdfToCosmosDb'
  location: location
  properties: {
    definition: 'logicAppDefinition.json'
    parameters: {
      '$connections': {
        value: {
          datalakestore: {
            connectionId: dataLakeStoreAccount.id
          }
          formrecognizer: {
            connectionId: formRecognizerConnection.id
          }
          cosmosdb: {
            connectionId: listKeys(cosmosDbAccount.id, '2021-04-15-preview').primaryMasterKey
          }
        }
      }
      dataLakeStoreFileSystemName: {
        value: 'myFileSystem'
      }
      dataLakeStoreFolderPath: {
        value: 'pdfs'
      }
    }
  }
}
