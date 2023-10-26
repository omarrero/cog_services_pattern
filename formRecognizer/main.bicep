@description('Location for all resources.')
param location string
@description('Base name that will appear for all resources.')
param baseName string = 'olivio'
@description('Three letter environment abreviation to denote environment that will appear in all resource names')
param environmentName string = 'dev'
@description('Form Recognizer Sku')
param formRecognizerSKU string


targetScope = 'subscription'

var regionReference = {
  centralus: 'cus'
  eastus2: 'eus2'
  westus: 'wus'
  westus2: 'wus2'
}
var nameSuffix = '${baseName}-${environmentName}-${regionReference[location]}'
var resourceGroupName = 'rg-${nameSuffix}'
var language = 'Bicep'

/* Since we are mismatching scopes with a deployment at subscription and resource at Resource Group
 the main.bicep requires a resource Group deployed at the subscription scope, all modules will be at the Resource Group scope
 */

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' ={
  name: resourceGroupName
  location: location
  tags:{
    Customer: 'NTSprint'
    Language: language
  }
}

module formRecognizer 'modules/formRecognizer.module.bicep' ={
  name: 'formRecognizerModule'
  scope: resourceGroup
  params:{
    location: location
    language: language
    formRecognizerSKU: formRecognizerSKU
    formRecognizerName: nameSuffix

  }
}
