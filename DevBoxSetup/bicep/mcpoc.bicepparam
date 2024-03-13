using 'devbox_main.bicep'

// VNet required for any dev pools created with bicep. The cli and portal will automatically create a Vnet and subnet if no network connection is specified
// this template assumes that there will be other, non-isolated (i.e. connected to internal resources) networks, but sets up an insolated network connection for all other cases
// THE TEMPLATE DOES NOT CREATE THIS VNET OR SUBNET
param isolatedVNetName = ''
param isolatedSubnetName = ''
param isolatedVvNetRgName = ''

// dev center names
param devCenterName = ''
param projectName = 'POC Project'
param projectDescription = 'Project to test the provisioning of Dev Boxes in the Metcash environment.'

// Principal Id of user or group to add to the DevCenter Dev Box User role for the project. Remove to create manually.
param devboxProjectUser = ''
