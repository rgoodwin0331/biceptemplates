@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
@allowed([
'21h1-ent-g2'
'win10-22h2-ent'
])
param OSVersion string = 'win10-22h2-ent'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2s_v5'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Virtual Network Name')
param vnetName string

@description('Subnet Name')
param subnetName string

@description('Prefix for VM Name i.e. THS')
param prefix string




/*@description('AD Domain FQDN')
param adDomain string

@description('Domain Admin Username')
param domainAdmin string

@description('Domain Admin Password')
@secure()
param domainPassword string

@description('Restart Option true/false')
param restart string
*/

var vmName = '${prefix}-mstimage'
var nicName = 'nic-${vmName}'
var osDiskName = 'osdisk-${vmName}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
  resource snet 'subnets' existing = {
    name: subnetName
  }
}


resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet::snet.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
        patchSettings: {
          patchMode: 'Manual'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      allowExtensionOperations: true
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
        storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
        diskSizeGB: 127
        name: osDiskName
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
   } 
}
resource windowsVMGuestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vm
  name: 'AzurePolicyforWindows'
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
    protectedSettings: {}
  }
}


/*resource windowsVMJoinManagedDomain'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: vm
  name: 'JoinManagedDomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: adDomain
      User: domainAdmin
      Restart: restart
      Options: 3
    }
    protectedSettings: {
      Password: domainPassword
    }
  }
}*/
