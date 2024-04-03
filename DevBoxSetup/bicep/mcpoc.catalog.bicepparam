using 'devbox_catalog.bicep'
// az deployment group create --resource-group mc-devbox-poc --parameters mcpoc.catalog.bicepparam

param devCenterName = 'Core-Systems'

param catalogName = 'Core-Systems-Catalog'

param catalogRepoType = 'gitHub'

param catalogRepoBranch = 'main'
param catalogRepoPath = '/Tasks'
param catalogRepoUri = 'https://github.com/davidxw/devcenter-catalog.git'
param catalogRepoPAT = ''

param keyVaultName = ''


