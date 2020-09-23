param(
      $propertiesPath="$PSScriptRoot\test_data\workbooks.e2e.properties",
      $filePathCSV="$PSScriptRoot\test_data\data.csv",
      $dryRun=$false
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
        $status = sendJMeterDataToLogAnalytics `
                            -propertiesPath "$propertiesPath" `
                            -filePathCSV "$filePathCSV"
    }else{
        $status=200
        Write-Host "Data Upload Mocked"
    }
    if ("$status" -ne "200"){
        Write-Error "Data has not been uploaded $status" -ErrorAction Stop
    }
}
run