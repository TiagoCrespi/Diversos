#Váriaveis
$Origem = "VMDataTools\ORIGEM"
$Destino = "VMDataTools\DESTINO"
$Compartilhado = "C:\Compartilhado"

#install-module dbatools
#Import-Module dbatools
Remove-DbaDatabase -SqlInstance $destino  -Database "db_DbaTools"
Remove-DbaLogin -SqlInstance $Destino -Login UserSQLADM, UserOwnerBD
Remove-DbaAgentJob -SqlInstance $Destino -job "JB_backupfull"
Remove-DbaAgentOperator -SqlInstance $Destino -Operator "DBA"
Remove-DbaAgentAlert -SqlInstance $Destino -Alert "RecursosInsuficientes"
Remove-DbaLinkedServer -SqlInstance $Destino -LinkedServer "vmdatatools\destino"

#Backup-DbaDatabase -SqlInstance $Origem   -CopyOnly -CompressBackup -Path $Compartilhado -Database db_DbaTools, db_NMigra -Type Full

