#Import-Module az
#Função para retornar o número da semana do ano
function Get-WeekNumber([datetime]$DateTime ) {
    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
    $cultureInfo.Calendar.GetWeekOfYear($DateTime,$cultureInfo.DateTimeFormat.CalendarWeekRule,$cultureInfo.DateTimeFormat.FirstDayOfWeek)
}

### Seta vari�veis 

$AzureAccount = "<Nome da conta do blob>"
$AzureAccountKey = "<Chave SAS do blob>"
$ContainerName = "<Nome do container>"
# Define a retenção
$nrRetencionWeek = 1

$nrWeek = Get-WeekNumber(get-date)

#Valida o nome do arquivo para remoção
if ($nrWeek -le $nrRetencionWeek)  {
    #Retorna o número da ultima semana do ano
    [datetime]$ultimodia = "12/31/" + ((Get-Date).Year -1)
    $nrLastWeekYear = Get-WeekNumber($ultimodia)

    $nrWeek1 = $nrLastWeekYear + $nrWeek
    $nrWeekRemove = $nrWeek1 - $nrRetencionWeek
}
else {
    $nrWeekRemove = $nrWeek - $nrRetencionWeek
}

if ($nrWeekRemove -eq 0) {
    $nrWeekRemove = 1
}


$ctx = New-AzStorageContext -StorageAccountName $AzureAccount -SasToken $AzureAccountKey

#Cria filtro para o nome dos arquivos que serão removidos
$filter = '*' + $nrWeekRemove + '*'

#Comando de remoção dos arquivos do containter
Get-AzStorageBlob -Container $ContainerName -Context $ctx |Where-Object { $_.Name -like $filter} |Remove-AzStorageBlob -WhatIf




