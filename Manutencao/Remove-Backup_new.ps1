#Import-Module az
#Função para retornar o número da semana do ano
function Get-WeekNumber([datetime]$DateTime ) {
    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
    $cultureInfo.Calendar.GetWeekOfYear($DateTime,$cultureInfo.DateTimeFormat.CalendarWeekRule,$cultureInfo.DateTimeFormat.FirstDayOfWeek)
}

# Seta vari�veis 
$AzureAccount = "stgbkpsqlprosalute01"
$AzureAccountKey = "sv=2019-02-02&ss=bfqt&srt=sco&sp=rwdlacup&se=2030-01-22T20:58:54Z&st=2020-01-22T12:58:54Z&spr=https&sig=n3EwusT4LhdyznYs2K0BNOEhTs3sW9L48Z5Wq5sSZks%3D"
$ContainerName = "lifeadministrativo"

# Define a retenção
$nrRetencionWeek = 1

$nrWeek = Get-WeekNumber(get-date)
#$nrWeek = 20

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

$filter = '*' + $nrWeekRemove + '*'
$filter
Get-AzStorageBlob -Container $ContainerName -Context $ctx |Where-Object { $_.Name -like $filter} |Remove-AzStorageBlob -WhatIf




