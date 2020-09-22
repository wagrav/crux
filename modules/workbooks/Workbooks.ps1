param(
      $propertiesPath="$PSScriptRoot\test_data\workbooks.e2e.properties",
      $filePathCSV="$PSScriptRoot\test_data\data.csv"
)

Import-Module $PSScriptRoot\Workbooks.psm1 -Force

Function sendJMeterDataToLogAnalytics($propertiesPath, $filePathCSV)
{
    $status = 999
    try
    {
        $status = SendDataToLogAnalytics `
                        -propertiesFilePath "$propertiesPath" `
                        -filePathCSV "$filePathCSV" `
                        -filePathJSON "$PSScriptRoot\test_data\results.json"
    }catch {
        Write-Host $_
    } finally {
        Write-Host " - Data sent with HTTP status $status"
        Write-Host " - propertiesPath $propertiesPath"
        Write-Host " - jsonFilePath $jsonFilePath"
    }
    return $status
}
Function run(){
    $status = sendJMeterDataToLogAnalytics `
                            -propertiesPath "$propertiesPath" `
                            -filePathCSV "$filePathCSV"
}
run