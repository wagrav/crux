param(
      $propertiesPath="$PSScriptRoot\test_data\workbooks.e2e.properties",
      $filePathCSV="$PSScriptRoot\test_data\data.csv",
      $outFilePathCSV="$PSScriptRoot\test_data\out_data.csv",
      $dryRun=$false,
      $jmeterArgs = 'dummy args',
      $buildId = 'local',
      $buildStatus = 'unknown',
      $pipelineId = 'local'
)

Import-Module $PSScriptRoot\Workbooks.psm1 -Force

Function sendJMeterDataToLogAnalytics($propertiesPath, $filePathCSV)
{
    $status = 999
    $filePathJSON = "$PSScriptRoot/test_data/results.json"
    try
    {
        $status = SendDataToLogAnalytics `
                        -propertiesFilePath "$propertiesPath" `
                        -filePathCSV "$filePathCSV" `
                        -filePathJSON "$filePathJSON"

    }catch {
        Write-Host $_
    } finally {
        Write-Host ""
        Write-Host " - Data sent with HTTP status $status"
        Write-Host " - propertiesPath $propertiesPath"
        Write-Host " - filePathJSON $filePathJSON"
    }
    return $status
}
Function addMetaDataToCSV($filePathCSV, $outFilePathCSV ){
    $inputTempFile = New-TemporaryFile
    $outputTempFile = New-TemporaryFile
    Copy-Item -Path $filePathCSV -Destination $inputTempFile
    $hash = @{
        jmeterArgs = $jmeterArgs
        buildId = $buildId
        buildStatus = $buildStatus
        pipelineId = $pipelineId
    }
    foreach ($h in $hash.GetEnumerator()) {
        Write-Host "$($h.Name): $($h.Value)"
        AddColumnToCSV -filePathCSV $inputTempFile -outFilePathCSV $outputTempFile -columnHeader "$($h.Name)" -columnFieldsValue "$($h.Value)"
        Copy-Item -Path $outputTempFile -Destination $inputTempFile
    }
    Copy-Item $inputTempFile -Destination $outFilePathCSV
}
Function run(){
    Write-Host "propertiesPath $propertiesPath"
    Write-Host "filePathCSV $filePathCSV"
    Set-Variable AZURE_POST_LIMIT -option Constant -value 30
    If( -Not $dryRun)
    {
        addMetaDataToCSV -filePathCSV $filePathCSV -outFilePathCSV $outFilePathCSV
        $sizeMB = ((Get-Item $outFilePathCSV).length/1MB)
        If ($sizeMB -gt $AZURE_POST_LIMIT){
            Write-Error "File size exceeds limit of 30 Megs: $sizeMB Megs" -ErrorAction Stop
        }
        $status = sendJMeterDataToLogAnalytics `
                            -propertiesPath "$propertiesPath" `
                            -filePathCSV "$outFilePathCSV"
    }else{
        $status=200
        Write-Host "Data Upload Mocked"
    }
    if ("$status" -ne "200"){
        Write-Error "Data has not been uploaded $status" -ErrorAction Stop
    }
}
run