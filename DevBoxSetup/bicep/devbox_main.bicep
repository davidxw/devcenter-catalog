param location string = resourceGroup().location
// This template creates the basic elements of a Dev Box installation:
// 1 x Dev Center
// 1 x Project
// 1 x Network Connection
// 1 x Dev Box definition
// 1 x Dev Box pool in the created project, attached to the created network, and using the created Dev Box definition

// VNet required for any dev pools created with bicep. The cli and portal will automatically create a Vnet and subnet if no network connection is specified
// this template assumes that there will be other, non-isolated (i.e. connected to internal resources) networks, but sets up an insolated network connection for all other cases
// THE TEMPLATE DOES NOT CREATE THIS VNET OR SUBNET
param isolatedVNetName string = 'mc-vnet'
param isolatedSubnetName string = 'devbox'
param isolatedVNetRgName string = 'mc-devbox-poc-core'

// dev center names
param devCenterName string = 'McDevCenter2'
param projectName string = 'McDev1Project2'
param projectDescription string = 'Project 2'

// this template creates a single dev pool using the above definition and connected to the isolated network
param devPoolName string = 'VS2022_vm8_32_256-isolated'

// Principal Id of user or group to add to the DevCenter Dev Box User role for the project
param devboxProjectUser string = ''

// only required if you are craeting a Tasks Catalog - leave 'catalogName' empty if you are not creating a catalog
// To create the required PAT tokens see here: // https://learn.microsoft.com/en-us/azure/deployment-environments/how-to-configure-catalog?tabs=GitHubRepoPAT#create-a-personal-access-token-in-github
param catalogName string = ''
param catalogRepoBranch string = ''
param catalogRepoPath string = ''
param catalogRepoUri string = ''

param keyVaultName string = ''
param catalogRepoPAT string = ''

var devBoxDefinitionName = 'Win11_VS2022_vm8_32_256'

var isolatedNetworkConnectionName = 'con-isolated-${isolatedVNetName}'
var isolatedConnectedNetworkName = 'dcon-isolated-${isolatedVNetName}'

resource devCenter 'Microsoft.DevCenter/devcenters@2023-04-01' = {
  name: devCenterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

// this template creates a single devbox deinition - can be extended to multiple definitions (a definition does not create an instance of a devbox, only a possible combination of image and sku)
module vs2022 'devbox_defn.bicep' = {
  name: '${deployment().name}_devbox_defn_vs2022'
  params: {
    devBoxDefinitionName: devBoxDefinitionName
    devCenterName: devCenterName
    location: location
    image: 'vs2022win11m365'
    sku: 'vm8core32memory_256'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: isolatedVNetName
  scope: resourceGroup(isolatedVNetRgName)
}

resource networkconnection 'Microsoft.DevCenter/networkConnections@2023-04-01' = {
  name: isolatedNetworkConnectionName
  location: location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: '${vnet.id}/subnets/${isolatedSubnetName}'
    networkingResourceGroupName: 'NI_${isolatedNetworkConnectionName}_${vnet.location}'
  }
}

resource attachedNetwork 'Microsoft.DevCenter/devcenters/attachednetworks@2023-04-01' = {
  name: isolatedConnectedNetworkName
  parent: devCenter
  properties: {
    networkConnectionId: networkconnection.id
  }
}

resource project 'Microsoft.DevCenter/projects@2023-04-01' = {
  name: projectName
  location: location
  properties: {
    description: projectDescription
    devCenterId: devCenter.id
    maxDevBoxesPerUser: 3
  }
}

resource devPool 'Microsoft.DevCenter/projects/pools@2023-04-01' = {
  name: devPoolName
  parent: project
  location: location
  properties: {
    devBoxDefinitionName: vs2022.outputs.devBoxDefinitionName
    licenseType: 'Windows_Client'
    localAdministrator: 'Disabled'
    networkConnectionName: isolatedConnectedNetworkName
  }
}

// add DevCenter Dev Box User role to provided principal - gives permission to create dev boxes in the project
var devCenterDevBoxUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '45d50f46-0b78-4001-a660-4198cbe8cd05')
resource projectUserRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(devboxProjectUser)) {
  scope: project
  name: guid(project.id, devboxProjectUser, devCenterDevBoxUserRoleId)
  properties: {
    roleDefinitionId: devCenterDevBoxUserRoleId
    principalType: 'User'
    principalId: devboxProjectUser
  }
}

// create catalog
module catalog 'devbox_catalog.bicep' =  if (!empty(catalogName)) {
  name: '${deployment().name}_catalog'
  params: {
    devCenterName: devCenterName
    keyVaultName: keyVaultName
    catalogRepoBranch: catalogRepoBranch
    catalogRepoPath: catalogRepoPath
    catalogName: catalogName
    catalogRepoPAT: catalogRepoPAT
    catalogRepoUri: catalogRepoUri
  }
}
