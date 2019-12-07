#Import-Module Az -Force
#Connect-AzAccount

# criação do storageaccount e container
New-AzResourceGroupDeployment -Name tdcpoa -ResourceGroupName tdcpoa  `
    -TemplateFile "D:\OneDrive - CRESPIDB\OneDrive - CRESPIDB - Soluções em Plataformas de Dados\Palestras e Artigos\Palestras\Migração para o Azure\tdcpoa\Storage\template.json" `
    -TemplateParameterFile "D:\OneDrive - CRESPIDB\OneDrive - CRESPIDB - Soluções em Plataformas de Dados\Palestras e Artigos\Palestras\Migração para o Azure\tdcpoa\Storage\parameters.json"

$storageacount = Get-AzStorageAccount -ResourceGroupName tdcpoa `
    -Name stgbackupmigracao 
New-AzStorageContainer -Context $storageacount.Context -Name backupmigracao

# Gera chave de acessoa ao container (SAS)
$nmcontainer = "stgbackupmigracao"
$storageacount = Get-AzStorageAccount -ResourceGroupName tdcpoa `
    -StorageAccountName $nmcontainer
$sas = New-AzStorageContainerSASToken -Name teste -Context $storageacount.Context -
$sas

# instancia o import database
$importRequest = 
New-AzSqlDatabaseExport `
    -ResourceGroupName tdcpoa `
    -ServerName srvtdcMigracao -DatabaseName MigracaoAzure `
    -DatabaseMaxSizeBytes 20000  `
    -StorageUri  https://stgbackupmigracao.blob.core.windows.net/$nmcontainer/sample.bacpac `
    -StorageKeyType SharedAccessKey `
    -StorageKey $sas `
    -Edition basic `
    -ServiceObjectiveName "P6" `
    -AdministratorLogin tiagocrespi `
    -AdministratorLoginPassword $(ConvertTo-SecureString -String "Tdc2019BdAzure" -AsPlainText -Force)


Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest

