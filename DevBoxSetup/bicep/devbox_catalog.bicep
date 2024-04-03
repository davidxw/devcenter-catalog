param devCenterName string

param catalogName string
@allowed(['gitHub', 'adoGit'])
param catalogRepoType string = 'gitHub'
param catalogRepoBranch string
param catalogRepoPath string
param catalogRepoUri string
param catalogRepoPAT string

param keyVaultName string
param secretName string = '${devCenterName}-${catalogName}-token'

var catalogProperies = {
      branch: catalogRepoBranch
      path: catalogRepoPath
      secretIdentifier: 'https://${keyVaultName}.vault.azure.net/secrets/${secretName}'
      uri: catalogRepoUri
    }

// keyvault
resource keyVault 'Microsoft.KeyVault/vaults@2023-04-01' existing = {
  name: keyVaultName
}

// secret
resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: secretName
  parent: keyVault
  properties: {
    value: catalogRepoPAT
  }
}

// catalog
resource devCenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devCenterName
}

// give dev center Key Vault Secrets Reader role on secret
var keyVaultSecretReaderRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
resource projectUserRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: secret
  name: guid(devCenter.id, devCenter.name, keyVaultSecretReaderRoleId, secretName)
  properties: {
    roleDefinitionId: keyVaultSecretReaderRoleId
    principalType: 'ServicePrincipal'
    principalId: devCenter.identity.principalId
  }
}

resource tasksCatalog 'Microsoft.DevCenter/devcenters/catalogs@2023-04-01' = {
  name: catalogName
  parent: devCenter
  properties: (catalogRepoType == 'gitHub') ? {
    gitHub: catalogProperies
  } : {
    adoGit: catalogProperies
  }
}


