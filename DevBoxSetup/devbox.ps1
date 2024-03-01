# 0. Install or upgrade the 'devcenter' extension to access Azure DevBox functionalities.
az extension add --upgrade -n devcenter

# Set Variables
$ResourceGroupName="mc-devbox-poc-1"
$ResourceLocation="australiaeast"
$DevCenterName="McDevCenter1"
$ProjectName="McDev1Project1"
$ProjectDescription='Project 1'
$DevBoxDefinitionName="McWin11-16"
$DevPool="DevPool1"
$SubscriptionId="b096bf45-e5d7-4d85-9dfc-3e7b04218307"

$NetworkRGName="mc-devbox-poc-core"
$NetworkVnetName="mc-vnet"
$NetworkSubnetName="devbox"

$DevBoxSku="general_i_8c32gb256ssd_v2"
$DevBoxStorage="ssd_256gb"

# who am i?
$account = az account show | ConvertFrom-Json

# Create a new RG
az group create --name $ResourceGroupName --location $ResourceLocation

# 1. Create Dev Center (should take about 2-3 mins)
az devcenter admin devcenter create --location $ResourceLocation --name $DevCenterName --identity-type "SystemAssigned" --resource-group $ResourceGroupName

# Create a network connection
$nc=az devcenter admin network-connection create --location $ResourceLocation --domain-join-type "AzureADJoin" `
    --subnet-id "/subscriptions/$SubscriptionId/resourceGroups/$NetworkRGName/providers/Microsoft.Network/virtualNetworks/$NetworkVnetName/subnets/$NetworkSubnetName" `
    --name "mcnetwork" --resource-group $ResourceGroupName | ConvertFrom-Json

# Get your Dev-center-Id
$DevCenterId="/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.DevCenter/devcenters/$DevCenterName"

# Attach network connectionto dev center
az devcenter admin attached-network create --attached-network-connection-name "mcnetwork" `
--network-connection-id $nc.id `
--dev-center-name $DevCenterName --resource-group $ResourceGroupName

# 2. Next create a project (takes about 3-4 mins)
az devcenter admin project create --location $ResourceLocation --description "$ProjectDescription" --dev-center-id "$DevCenterId" --name $ProjectName --resource-group $ResourceGroupName --max-dev-boxes-per-user "3"


# 3. Set your DevBox compute gallery image reference Id
$ImageReferenceId="$DevCenterId/galleries/Default/images/microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2"

# Create devbox definitions (takes about 2-3 minutes)
az devcenter admin devbox-definition create --location $ResourceLocation  `
    --image-reference id="$ImageReferenceId" --name $DevBoxDefinitionName  `
    --dev-center-name "$DevCenterName"  --resource-group $ResourceGroupName  `
    --os-storage-type $DevBoxStorage --sku name=$DevBoxSku --hibernate-support enabled


# 4. Create DevPool (takes about 5 mins)(brings it all together!!!)
az devcenter admin pool create --location $ResourceLocation  --devbox-definition-name $DevBoxDefinitionName `
    --network-connection-name $nc.name --pool-name $DevPool --project-name $ProjectName `
    --resource-group $ResourceGroupName --local-administrator "Enabled" 

# give current user "DevCenter Dev Box User" role on the project to quickly test the devbox
az role assignment create --role "DevCenter Dev Box User" --scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.DevCenter/projects/$ProjectName" --assignee $account.user.name


### Create a task catalog

$KeyVaultName="McKeyVault2"
$SecretName="McGitHubPAT"
$Repo="https://github.com/davidxw/devcenter-catalog.git"
# set in command line - $env:PAT='your-pat'
$PAT=$env:PAT

# Create a keyvault to hold the PAT
az keyvault create --location $ResourceLocation --name $KeyVaultName --resource-group $ResourceGroupName --enable-rbac-authorization "true"

# Give self access to create secrets
az role assignment create --role "Key Vault Administrator" --scope "/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName/providers/Microsoft.KeyVault/vaults/$KeyVaultName" --assignee $account.user.name

# Create a secret in the keyvault
$secret=az keyvault secret set --name $SecretName --vault-name $KeyVaultName --value $PAT | ConvertFrom-Json

# Give the devcenter permissions to read the secret
$dc = az devcenter admin devcenter show --name $DevCenterName --resource-group $ResourceGroupName | ConvertFrom-Json
az role assignment create --role "Key Vault Secrets User" --scope "/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName/providers/Microsoft.KeyVault/vaults/$KeyVaultName/secrets/$SecretName" --assignee $dc.identity.principalId

# Create a catalog of config tasks
az devcenter admin catalog create --git-hub path="/Tasks" branch="main" uri=$Repo secret-identifier="$secret.id" --name "TaskCatalog" --dev-center-name $DevCenterName --resource-group $ResourceGroupName
az devcenter admin catalog create --git-hub path="/Tasks" branch="main" uri=$Repo secret-identifier="https://$KeyVaultName.vault.azure.net/secrets/$SecretName" --name "TaskCatalog" --dev-center-name $DevCenterName --resource-group $ResourceGroupName

# az devcenter admin catalog get-sync-error-detail --name "TaskCatalog" --dev-center-name $DevCenterName --resource-group $ResourceGroupName