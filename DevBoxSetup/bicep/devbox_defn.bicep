param devCenterName string

param nameseed string = 'dbox'
param devBoxDefinitionName string = '${nameseed}_${image}_${sku}'
param location string = resourceGroup().location

param galleryName string = 'Default'

@allowed(['Disabled', 'Enabled'])
param hibernameSupport string = 'Disabled'

@allowed(['vm8core32memory_256', 'vm16core64memory_512', 'vm32core128memory_512'])
param sku string = 'vm8core32memory_256'

@allowed(['win11', 'vs2022win11m365'])
param image string = 'vs2022win11m365'

var skuMap = {
  vm8core32memory_256: 'general_i_8c32gb256ssd_v2'
  vm16core64memory_512: 'general_i_16c64gb512ssd_v2'
  vm32core128memory_512: 'general_i_16c64gb512ssd_v2'
}

var defaultImageMap = {
  win11: 'microsoftwindowsdesktop_windows-ent-cpc_win11-22h2-ent-cpc-os'
  vs2022win11m365: 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
}

var storage = 'ssd_${split(sku, '_')[1]}gb'

resource dc 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devCenterName
}

resource gallery 'Microsoft.DevCenter/devcenters/galleries@2022-11-11-preview' existing = {
  name: galleryName
  parent: dc
}

resource galleryimage 'Microsoft.DevCenter/devcenters/galleries/images@2022-11-11-preview' existing = {
  name: defaultImageMap['${image}']
  parent: gallery
}

resource devBoxDefinition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2023-04-01' = {
  parent: dc
  name: devBoxDefinitionName
  location: location
  properties: {
    imageReference: {
      id: galleryimage.id
    }
    osStorageType: storage
    sku: {
      name: skuMap['${sku}']
    }
    hibernateSupport: hibernameSupport
  }
}

output devBoxDefinitionName string = devBoxDefinition.name
