@description('Username for the FortiGate VM')
param adminUsername string

@description('Password for the FortiGate VM')
@minLength(15)
@secure()
param adminPassword string

@description('Naming prefix for a fortigate name')
param fortiGateNamePrefix string

@description('Custom naming for the deployed FortiGate resources. This will override the automatic generation based on the prefix for the FortiGate name.')
param fortiGateName string = 'vm-${fortiGateNamePrefix}-fgta'

@description('Identifies whether to to use PAYG (on demand licensing) or BYOL license model (where license is purchased separately')
@allowed([
  'fortinet_fg-vm'
  'fortinet_fg-vm_payg_2022'
])
param fortiGateImageSKU string = 'fortinet_fg-vm'

@description('Select the image version')
@allowed([
  '6.4.9'
  '7.0.0'
  '7.0.1'
  '7.0.2'
  '7.0.3'
  '7.0.4'
  '7.0.5'
  '7.0.6'
  '7.0.8'
  '7.0.9'
  '7.2.0'
  '7.2.1'
  '7.2.2'
  '7.2.3'
  'latest'
])
param fortiGateImageVersion string = '7.0.9'

@description('Virtual Machine size selection - must be F4 or other instance that supports 4 NICs')
@allowed([
  'Standard_F2s'
  'Standard_F4s'
  'Standard_F8s'
  'Standard_F16s'
  'Standard_F2'
  'Standard_F4'
  'Standard_F8'
  'Standard_F16'
])
param instanceType string = 'Standard_F2s'

@description('Accelerated Networking enables direct connection between the VM and network card')
@allowed([
  true
  false
])
param acceleratedNetworking bool = true

@description('Choose between an existing or new public IP address linked to the external interface of the FortiGate VM')
@allowed([
  'new'
  'existing'
  'none'
])
param publicIP1NewOrExisting string = 'new'


@description('Type of public IP address')
@allowed([
  'Dynamic'
  'Static'
])
param publicIP1AddressType string = 'Static'

@description('Type of public IP address')
param publicIP1SKU string = 'Standard'

@description('Identify whether to use a new or existing vnet')
@allowed([
  'new'
  'existing'
])
param vnetNewOrExisting string = 'existing'

@description('Name of the Azure virtual network, required if utilizing an existing VNET.')

param vnetName string = 'vnet-hub-prod-${location}'

@description('Resource Group containing the existing virtual network, leave blank if a new VNET is being utilize')
param vnetResourceGroup string = resourceGroup().name

@description('Virtual Network Address prefix')
param vnetAddressPrefix string = '172.18.0.0/23'

@description('Subnet 1 Name')
param subnet1Name string = 'snet-fortigate-untrust'

@description('Subnet 1 Prefix')
param subnet1Prefix string = '172.18.0.0/24'

@description('Subnet 1 start address, 1 consecutive private IPs are required')
param subnet1StartAddress string = '172.18.0.4'

@description('Subnet 2 Subnet')
param subnet2Name string = 'snet-fortigate-trust'

@description('Subnet 2 Prefix')
param subnet2Prefix string = '172.18.1.0/24'

@description('Subnet 2 start address, 1 consecutive private IPs are required')
param subnet2StartAddress string = '172.18.1.4'


@description('Enable Serial Console')
@allowed([
  true
  false
])
param serialConsole bool = true

@description('Custom Data')
param fortiGateAdditionalCustomData string = ''

@description('Connect to FortiManager')
@allowed([
  'yes'
  'no'
])
param fortiManager string = 'no'

@description('FortiManager IP or DNS name to connect to on port TCP/541')
param fortiManagerIP string = 'fm01.thrivenetworks.com'

@description('FortiManager serial number to add the deployed FortiGate into the FortiManager')
param fortiManagerSerial string = ''

@description('FortiGate BYOL license content')
param fortiGateLicenseBYOL string = ''

@description('FortiGate BYOL Flex-VM license token')
param fortiGateLicenseFlexVM string = ''

@description('Deployed By Engineer')
param deployedby string

@description('Initial Deployment Date')
param deployeddate string = utcNow('d')

@description('Location for all resources.')
param location string = resourceGroup().location
param fortinetTags object = {
  publisher: 'Fortinet'
  provider: '6EB3B02F-50E5-4A3E-8CB8-2E12925831VM'
  biceptemplate: 'fortigate.bicep:v1'
  deployedby: deployedby
  deployeddate: deployeddate
}

var imagePublisher = 'fortinet'
var imageOffer = 'fortinet_fortigate-vm_v5'
var routeTableProtectedName = 'rt-${fortiGateName}-trust'
var routeTableProtectedId = routeTableProtected.id
var NSGName = 'nsg-${fortiGateName}'
var NSGId = NSG.id
var publicIP1Name = 'pip-${fortiGateName}'
var fgtNic1Name = 'nic-${fortiGateName}-untrust'
var fgtNic1Id = fgtNic1.id
var fgtNic2Name = 'nic-${fortiGateName}-trust'
var fgtNic2Id = fgtNic2.id



var subnet1Id = ((vnetNewOrExisting == 'new') ? resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet1Name) : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnet1Name))
var subnet2Id = ((vnetNewOrExisting == 'new') ? resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet2Name) : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnet2Name))
var fmgCustomData = ((fortiManager == 'yes') ? '\nconfig system central-management\nset type fortimanager\n set fmg ${fortiManagerIP}\nset serial-number ${fortiManagerSerial}\nend\n config system interface\n edit port1\n append allowaccess fgfm\n end\n config system interface\n edit port2\n append allowaccess fgfm\n end\n' : '')
var customDataHeader = 'Content-Type: multipart/mixed; boundary="12345"\nMIME-Version: 1.0\n\n--12345\nContent-Type: text/plain; charset="us-ascii"\nMIME-Version: 1.0\nContent-Transfer-Encoding: 7bit\nContent-Disposition: attachment; filename="config"\n\n'
var customDataBody = 'config system sdn-connector\nedit AzureSDN\nset type azure\nnext\nend\nconfig router static\nedit 1\nset gateway ${sn1GatewayIP}\nset device port1\nnext\nedit 2\nset dst ${vnetAddressPrefix}\nset gateway ${sn2GatewayIP}\nset device port2\nnext\nend\nconfig system interface\nedit port1\nset mode static\nset ip ${sn1IPfgt}/${sn1CIDRmask}\nset description external\nset allowaccess ping ssh https\nnext\nedit port2\nset mode static\nset ip ${sn2IPfgt}/${sn2CIDRmask}\nset description internal\nset allowaccess ping ssh https\nnext\nend\n${fmgCustomData}${fortiGateAdditionalCustomData}\n'
var customDataLicenseHeader = '--12345\nContent-Type: text/plain; charset="us-ascii"\nMIME-Version: 1.0\nContent-Transfer-Encoding: 7bit\nContent-Disposition: attachment; filename="license"\n\n'
var customDataFooter = '\n--12345--\n'
var customDataCombined = '${customDataHeader}${customDataBody}${customDataLicenseHeader}${fortiGateLicenseBYOL}${customDataFooter}'
var fgtCustomData = base64((((fortiGateLicenseBYOL == '') && (fortiGateLicenseFlexVM == '')) ? customDataBody : customDataCombined))



var sn1IPArray = split(subnet1Prefix, '.')
var sn1IPArray2ndString = string(sn1IPArray[3])
var sn1IPArray2nd = split(sn1IPArray2ndString, '/')
var sn1CIDRmask = string(int(sn1IPArray2nd[1]))
var sn1IPArray3 = string((int(sn1IPArray2nd[0]) + 1))
var sn1IPArray2 = string(int(sn1IPArray[2]))
var sn1IPArray1 = string(int(sn1IPArray[1]))
var sn1IPArray0 = string(int(sn1IPArray[0]))
var sn1GatewayIP = '${sn1IPArray0}.${sn1IPArray1}.${sn1IPArray2}.${sn1IPArray3}'
var sn1IPStartAddress = split(subnet1StartAddress, '.')
var sn1IPfgt = '${sn1IPArray0}.${sn1IPArray1}.${sn1IPArray2}.${int(sn1IPStartAddress[3])}'
var sn2IPArray = split(subnet2Prefix, '.')
var sn2IPArray2ndString = string(sn2IPArray[3])
var sn2IPArray2nd = split(sn2IPArray2ndString, '/')
var sn2CIDRmask = string(int(sn2IPArray2nd[1]))
var sn2IPArray3 = string((int(sn2IPArray2nd[0]) + 1))
var sn2IPArray2 = string(int(sn2IPArray[2]))
var sn2IPArray1 = string(int(sn2IPArray[1]))
var sn2IPArray0 = string(int(sn2IPArray[0]))
var sn2GatewayIP = '${sn2IPArray0}.${sn2IPArray1}.${sn2IPArray2}.${sn2IPArray3}'
var sn2IPStartAddress = split(subnet2StartAddress, '.')
var sn2IPfgt = '${sn2IPArray0}.${sn2IPArray1}.${sn2IPArray2}.${int(sn2IPStartAddress[3])}'


resource routeTableProtected 'Microsoft.Network/routeTables@2020-11-01' = if (vnetNewOrExisting == 'new') {
  name: routeTableProtectedName
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  location: location
  properties: {
    routes: [
      {
        name: 'VirtualNetwork'
        properties: {
          addressPrefix: vnetAddressPrefix
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: sn2IPfgt
        }
      }
      {
        name: 'Subnet'
        properties: {
          addressPrefix: subnet2Prefix
          nextHopType: 'VnetLocal'
        }
      }
      {
        name: 'Default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: sn2IPfgt
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = if (vnetNewOrExisting == 'new') {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
          routeTable: {
            id: routeTableProtectedId
          }
        }
      }
    ]
  }
}

resource NSG 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: NSGName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAllInbound'
        properties: {
          description: 'Allow all in'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAllOutbound'
        properties: {
          description: 'Allow all out'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 105
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource publicIP1 'Microsoft.Network/publicIPAddresses@2020-11-01' = if (publicIP1NewOrExisting == 'new') {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: publicIP1Name
  location: location
  sku: {
    name: publicIP1SKU
  }
  properties: {
    publicIPAllocationMethod: publicIP1AddressType
  }
}

resource fgtNic1 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: fgtNic1Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'dynamic'
          subnet: {
            id: subnet1Id
          }
        }
      }
    ]
    enableIPForwarding: true
    enableAcceleratedNetworking: acceleratedNetworking
    networkSecurityGroup: {
      id: NSGId
    }
  }
  dependsOn: [ 
    vnet
   ]
}

resource fgtNic2 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: fgtNic2Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'dynamic'
          subnet: {
            id: subnet2Id
          }
        }
      }
    ]
    enableIPForwarding: true
    enableAcceleratedNetworking: acceleratedNetworking
    networkSecurityGroup: {
      id: NSGId
    }
  }
  dependsOn: [
    vnet
  ]
}

resource fgtVm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: fortiGateName
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  plan: {
    name: fortiGateImageSKU
    publisher: imagePublisher
    product: imageOffer
  }
  properties: {
    hardwareProfile: {
      vmSize: instanceType
    }
    osProfile: {
      computerName: fortiGateName
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: fgtCustomData
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: fortiGateImageSKU
        version: fortiGateImageVersion
      }
      osDisk: {
        createOption: 'FromImage'
        name: 'osdisk-${fortiGateName}'
        deleteOption: 'Delete'
      }
      dataDisks: [
        {
          diskSizeGB: 30
          lun: 0
          createOption: 'Empty'
          name: 'datadisk-1-${fortiGateName}'
          deleteOption: 'Delete'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
            deleteOption: 'Delete'
          }
          id: fgtNic1Id
        }
        {
          properties: {
            primary: false
            deleteOption: 'Delete'
          }
          id: fgtNic2Id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: serialConsole
      }
    }
  }

}

