####################################################
## Demo 1 - Migração em partes                  ####
####################################################
#install-module dbatools
#Import-Module dbatools
#Váriaveis
$Origem = "VMDataTools\ORIGEM"
$Destino = "VMDataTools\DESTINO"
$Compartilhado = "C:\Compartilhado"
$Excluir = "db_NMigra"
# Comando copy-dbadatabase
#remove-DbaDatabase -SqlInstance $destino -Database "db_DbaTools"
#remove-DbaDatabase -SqlInstance $destino -Database "db_NMigra"
Copy-DbaDatabase -Source $Origem -Destination $destino -BackupRestore -AllDatabases -ExcludeDatabase $Excluir -SharedPath $Compartilhado -NoBackupCleanup
Copy-DbaDatabase -Source $Origem -Destination $destino -DetachAttach -Reattach -AllDatabases -ExcludeDatabase $Excluir 
#-SourceSqlCredential $CredentialSQL -DestinationSqlCredential $CredentialSQL 

# Comando copy-dbalogin
#Remove-DbaLogin -SqlInstance $Destino  -Login UserSQLADM,UserOwnerBD
Copy-DbaLogin -Source $Origem -Destination $Destino 
Copy-DbaLogin -Source $origem -Destination $destino -ExcludeSystemLogins -KillActiveConnection

# Comando Copy-DbaAgentJob
#Remove-DbaAgentJob -SqlInstance $Destino  -job "JB_backupfull"
Copy-DbaAgentJob -Source $origem -Destination $destino -DisableOnDestination
Copy-DbaAgentJob -Source $origem -Destination $destino -DisableOnSource -Job # lista de jobs

# Comandos Copy-DbaAgentScheduler
#Remove-DbaAgentSchedule -SqlInstance $Destino  -Schedule "JS_Backupfull"
Copy-DbaAgentSchedule -Source $origem -Destination $destino 

# Comando Copy-DbaAgentOperator
#Remove-DbaAgentOperator -SqlInstance $Destino  -Operator "DBA"
Copy-DbaAgentOperator -Source $origem -Destination $destino
Copy-DbaAgentOperator -Source $origem -Destination $destino -Operator "DBA"

# Comandos Copy-DbaAgentAlert
#Remove-DbaAgentAlert -SqlInstance $Destino  -Alert "RecursosInsuficientes"
Copy-DbaAgentAlert -Source $origem -Destination $destino
Copy-DbaAgentAlert -Source $origem -Destination $destino -Alert "RecursosInsuficientes"

# Comandos Copy-DbaLinkedServer
#Remove-DbaLinkedServer -SqlInstance $Destino  -LinkedServer "vmdatatools\destino"
Copy-DbaLinkedServer -Source $origem -Destination $destino
Copy-DbaLinkedServer -Source $origem -Destination $destino -LinkedServer "vmdatatools\destino"

