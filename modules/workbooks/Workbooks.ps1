param(
      $propertiesPath="$PSScriptRoot\test_data\workbooks.e2e.properties",
      $filePathCSV="$PSScriptRoot\test_data\data.csv",
      $outFilePathCSV="$PSScriptRoot\test_data\out_data.csv",
      $dryRun=$false,
      $jmeterArgs = 'dummy args',
      $buildId = 'local',
      $buildStatus = 'unknown'
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
Function run(){
    Write-Host "propertiesPath $propertiesPath"
    Write-Host "filePathCSV $filePathCSV"

    If( -Not $dryRun)
    {
        $TempFile = New-TemporaryFile
        $TempFile2 = New-TemporaryFile
        AddColumnToCSV -filePathCSV $filePathCSV -outFilePathCSV $TempFile -columnHeader 'jmeterArgs' -columnFieldsValue "$jmeterArgs"
        AddColumnToCSV -filePathCSV $TempFile -outFilePathCSV "$TempFile2"-columnHeader 'buildId' -columnFieldsValue "$buildId"
        AddColumnToCSV -filePathCSV $TempFile2 -outFilePathCSV "$outFilePathCSV"-columnHeader 'buildStatus' -columnFieldsValue "$buildStatus"
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