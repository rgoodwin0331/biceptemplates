# Deploy Bicep Files in Azure

## PowerShell</br>
New-AzResourceGroupDeployment -ResourceGroupName <em>resource-group-name</em> -TemplateFile <em>path-to-bicep</em>

## Azure CLI</br>
az deployment group create --resource-group <em>resource-group-name</em> --template-file <em>path-to-bicep</em>
