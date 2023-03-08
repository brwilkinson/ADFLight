@allowed([
  'AZE2'
  'AZC1'
  'AEU2'
  'ACU1'
  'AWCU'
])
param Prefix string = 'ACU1'

@allowed([
  'I'
  'D'
  'T'
  'U'
  'P'
  'S'
  'G'
  'A'
])
param Environment string = 'D'

@allowed([
  '0'
  '1'
  '2'
  '3'
  '4'
  '5'
  '6'
  '7'
  '8'
  '9'
])
param DeploymentID string = '1'
param Stage object
param Extensions object
param Global object = {
  n: '1'
}
param DeploymentInfo object

@secure()
param vmAdminPassword string

@secure()
param devOpsPat string

@secure()
param sshPublic string

var Deployment = '${Prefix}-${Global.OrgName}-${Global.Appname}-${Environment}${DeploymentID}'
var DeploymentURI = toLower('${Prefix}${Global.OrgName}${Global.Appname}${Environment}${DeploymentID}')

var azBOTInfo = contains(DeploymentInfo, 'azBOTInfo') ? DeploymentInfo.azBOTInfo : []

var azBOT = [for (bot,index) in azBOTInfo : {
  match: ((Global.CN == '.') || contains(Global.CN, bot.Name))
}]

resource UAI 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: '${Deployment}-uaiKeyVaultSecretsGet'
}

resource KV 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: '${Deployment}-kvGlobal'
}

resource KVSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' existing = {
  name: 'localadmin'
  parent: KV
}

resource AppInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${DeploymentURI}AppInsights'
}

resource AzureBOT 'Microsoft.BotService/botServices@2021-05-01-preview' = [for (bot, index) in azBOTInfo : {
  name: '${Deployment}-bot${bot.Name}'
  kind: 'azurebot'
  location: 'global'
  sku: {
    name: bot.Sku
  }
  properties: {
    displayName: bot.Name
    msaAppType: 'UserAssignedMSI'
    msaAppId: UAI.properties.principalId
    msaAppTenantId: tenant().tenantId
    msaAppMSIResourceId: UAI.id
    openWithHint: 'bfcomposer://'
    appPasswordHint: KVSecret.id
    endpoint: ''
    developerAppInsightsApplicationId: AppInsights.properties.InstrumentationKey
    developerAppInsightKey: AppInsights.properties.InstrumentationKey
  }
}]

resource AzureBotTeamsChannel 'Microsoft.BotService/botServices/channels@2021-05-01-preview' = [for (bot, index) in azBOTInfo : {
  name: 'MsTeamsChannel'
  parent: AzureBOT[index]
  properties: {
    channelName: 'MsTeamsChannel'
    properties: {
      isEnabled: true
      enableCalling: true
    }
  }
}]

resource secretLink 'Microsoft.KeyVault/vaults/secrets/providers/links@2018-02-01' = [for (bot, index) in azBOTInfo : {
  name: '${Deployment}-kvGlobal/localadmin/Microsoft.Resources/provisioned-for'
  location: resourceGroup().location
  properties: {
    targetId: AzureBOT[index].id
    sourceId: KVSecret.id
  }
}]

output uaiid string = UAI.properties.principalId
