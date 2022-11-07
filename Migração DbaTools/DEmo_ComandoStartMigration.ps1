####################################################
## Demo 2 - Migração com um comando             ####
####################################################
#install-module dbatools
install-module sqlserver
#Import-Module dbatools
#Váriaveis
$Origem = "VMDataTools\ORIGEM"
$Destino = "VMDataTools\DESTINO"
$Compartilhado = "c:\Compartilhado"
$Excluir = "db_NMigra"

# Comando start-dbamigration


#Start-DbaMigration -Source $origem -Destination $destino -DetachAttach -Reattach -SharedPath $Compartilhado
Start-DbaMigration -Source $origem -Destination $destino -BackupRestore -DisableJobsOnDestination -SharedPath $Compartilhado -exclude StartupProcedures, DataCollector, DatabaseMail, PolicyManagement
Start-DbaMigration -Source $origem -Destination $destino -BackupRestore -DisableJobsOnDestination -ReuseSourceFolderStructure -SharedPath $Compartilhado -exclude StartupProcedures, DataCollector, DatabaseMail, PolicyManagement
