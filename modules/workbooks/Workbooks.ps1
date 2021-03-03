param(
      $PropertiesPath="$PSScriptRoot\test_data\workbooks.e2e.properties",
      $FilePathCSV="$PSScriptRoot\test_data\data.csv",
      $OutFilePathCSV="$PSScriptRoot\test_data\out_data.csv",
      $DryRun=$false,
      $JmeterArg = 'dummy args',
      $BuildId = 'local',
      $BuildStatus = 'unknown',
      $PipelineId = 'local'
)

Import-Module $PSScriptRoot\Workbooks.psm1 -Force

function Send-JMeterDataToLogAnalytics($PropertiesPath, $FilePathCSV)
{
    $status = 999
    $filePathJSON = "$PSScriptRoot/test_data/results.json"
    try
    {
        $status = Send-DataToLogAnalytics `
                        -PropertiesFilePath "$PropertiesPath" `
                        -FilePathCSV "$FilePathCSV" `
                        -FilePathJSON "$filePathJSON"

    }catch {
        Write-Host $_
    } finally {
        Write-Host ""
        Write-Host " - Data sent with HTTP status $status"
        Write-Host " - propertiesPath $PropertiesPath"
        Write-Host " - filePathJSON $filePathJSON"
    }
    return $status
}
function Add-MetaDataToCSV($FilePathCSV, $OutFilePathCSV ){
    $inputTempFile = New-TemporaryFile
    $outputTempFile = New-TemporaryFile
    Copy-Item -Path $FilePathCSV -Destination $inputTempFile
    $hash = [ordered]@{
        jmeterArgs = $JmeterArg
        buildId = $BuildId
        buildStatus = $BuildStatus
        pipelineId = $PipelineId
    }
    foreach ($h in $hash.GetEnumerator()) {
        #Write-Host "$($h.Name): $($h.Value)"
        Add-ColumnToCSV -filePathCSV $inputTempFile -outFilePathCSV $outputTempFile -columnHeader "$($h.Name)" -columnFieldsValue "$($h.Value)"
        Copy-Item -Path $outputTempFile -Destination $inputTempFile
    }
    Copy-Item $inputTempFile -Destination $OutFilePathCSV
}
function Start-Script(){
    Write-Host "Used properties: propertiesPath $PropertiesPath"
    $props = Get-Content -Path $PropertiesPath
    Write-Host "$props"
    Write-Host "Results to upload: filePathCSV $FilePathCSV"
    Set-Variable AZURE_POST_LIMIT -option Constant -value 30
    Add-MetaDataToCSV -filePathCSV $FilePathCSV -outFilePathCSV $OutFilePathCSV
    $sizeMB = ((Get-Item $OutFilePathCSV).length/1MB)
aaa
    if ($sizeMB -gt $AZURE_POST_LIMIT){
        Write-Error "File size exceeds limit of 30 Megs: $sizeMB Megs" -ErrorAction Stop
    }
    if( -Not $DryRun)
    {
        Write-Host "Uploading file with size $sizeMB MB"
        $status = Send-JMeterDataToLogAnalytics `
                            -propertiesPath "$PropertiesPath" `
                            -filePathCSV "$OutFilePathCSV"
    }else{
        $status=200
        Write-Host "Data Upload Mocked"
    }
    if ("$status" -ne "200"){
        Write-Error "Data has not been uploaded $status" -ErrorAction Stop
    }
}
Start-Script