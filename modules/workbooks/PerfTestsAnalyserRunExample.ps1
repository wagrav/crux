# You need to change import-modules to use approprate files
Import-module $PSScriptRoot\PerfTestsAnalyserFunctions.psm1
Import-module $PSScriptRoot\PerfTestsAnalyserConfig.psm1

$runDesc = ''
$StartTime = ''
$EndTime = ''
$jmeterJtlDir = ''
$jmeterXmlDir = ''
$TenatId = ''
$SpnId = ''
$SpnPwd = ''
$LogAnalyticsWorkspaceId = ''
$LogAnalyticsKey = ''

# You could create below file to store variables outside the git repository
try {
  SetVariables.ps1
}
catch {
  Write-Host "Error while loading SetVariable file" 
}

# Current working directory where temp/results needs to be processed. 
$location = "C:\tmp"

#region Create Config

Write-Host "StartDate: $StartTime and EndDate: $EndTime"

$conf = getConfigBody $runDesc $StartTime $EndTime $jmeterJtlDir $jmeterXmlDir
createConfig $location $conf 

# If not executed inside VSTS Azure Powershell Task (which created AZContext by itself with Connection credentials)
establishAzContextAsSPN $TenatId $SpnId $SpnPwd
#establishAzContextAsCurrentUser 

convertDownloadSourceData $location

uplaodSourceDataIntoLogAnalytics $location $LogAnalyticsWorkspaceId  $LogAnalyticsKey
