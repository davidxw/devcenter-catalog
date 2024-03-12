# 0. Install or upgrade the 'devcenter' extension to access Azure DevBox functionalities.
az extension add --upgrade -n devcenter

# Set Variables
$SubscriptionId="b096bf45-e5d7-4d85-9dfc-3e7b04218307"
$ResourceGroupName="mc-devbox-poc-1"
$ResourceLocation="australiaeast"

$DevCenterName="McDevCenter1"
$ProjectName="McDev1Project1"
$ProjectDescription='Project 1'
$DevBoxDefinitionName="McWin11-16"
$DevPool="DevPool1-isolated"

$DevBoxSku="general_i_8c32gb256ssd_v2"
$DevBoxStorage="ssd_256gb"

# who am i?
$account = az account show | ConvertFrom-Json

# Create a new RG
az group create --name $ResourceGroupName --location $ResourceLocation

# 1. Create Dev Center (should take about 2-3 mins)
az devcenter admin devcenter create --location $ResourceLocation --name $DevCenterName --identity-type "SystemAssigned" --resource-group $ResourceGroupName

# Get your Dev-center-Id
$DevCenterId="/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.DevCenter/devcenters/$DevCenterName"

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
    --pool-name $DevPool --project-name $ProjectName `
    --resource-group $ResourceGroupName --local-administrator "Enabled" 

# give current user "DevCenter Dev Box User" role on the project to quickly test the devbox
az role assignment create --role "DevCenter Dev Box User" --scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.DevCenter/projects/$ProjectName" --assignee $account.user.name

