Import-Module Az -Force
Connect-AzAccount
# criação do Grupo de Recursos
New-AzResourceGroup -Name Migracao -Location brazilsouth

# criação do SQL Database
New-AzResourceGroupDeployment -Name Migracao -ResourceGroupName Migracao  `
    -TemplateFile "<Troque Pelo Caminho do template>\SQLDatabase\template.json" `
    -TemplateParameterFile "<Troque Pelo Caminho do template>\SQLDatabase\parameters.json"


# criação da VM com Windows e SQL
New-AzResourceGroupDeployment -Name Migracao -ResourceGroupName Migracao  `
    -TemplateFile "<Troque Pelo Caminho do template>\Windows2016\template.json" `
    -TemplateParameterFile "<Troque Pelo Caminho do template>\Windows2016\parameters.json"

# criação do storageaccount e container
New-AzResourceGroupDeployment -Name Migracao -ResourceGroupName Migracao  `
    -TemplateFile "<Troque Pelo Caminho do template>\Storage\template.json" `
    -TemplateParameterFile "<Troque Pelo Caminho do template>\Storage\parameters.json"

$storageacount = Get-AzStorageAccount -ResourceGroupName Migracao `
    -Name stgbackupmigracao 
New-AzStorageContainer -Context $storageacount.Context -Name backupmigracao

# Gera chave de acessoa ao container (SAS)
$nmcontainer = "stgbackupmigracao"
$storageacount = Get-AzStorageAccount -ResourceGroupName Migracao `
    -StorageAccountName $nmcontainer
$sas = New-AzStorageContainerSASToken -Name teste -Context $storageacount.Context -


Remove-AzResourceGroup -Name Migracao
Remove-AzResourceGroup -Name NetworkWatcherRG


#Stop-AzVM -ResourceGroupName "Migracao" -Name "VMSQL1"
#Start-AzVM -ResourceGroupName "Migracao" -Name "VMSQL1"


# criação da VM com ubuntu
#New-AzResourceGroupDeployment -Name Migracao -ResourceGroupName Migracao  `
#    -TemplateFile "<Troque Pelo Caminho do template>\Ubuntu\template.json" `
#    -TemplateParameterFile "<Troque Pelo Caminho do template>\Ubuntu\parameters.json"