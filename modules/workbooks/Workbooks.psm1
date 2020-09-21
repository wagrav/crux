Import-Module $PSScriptRoot\Azure.psm1

Function JmeterCSVResultsToJSON($filePathCSV, $filePathJSON)
{
    try
    {
        $x = Get-Content -Path $filePathCSV -ErrorAction Stop
        $x = $x | ConvertFrom-Csv | ConvertTo-Json | Out-File -Encoding UTF8 $filePathJSON
    }catch [System.Management.Automation.ItemNotFoundException] {
        "IO Error while rading/writing file: {0},{1}" -f $filePathCSV, $filePathJSON
        "Terminating"
    }
    return
}

Function LoadProperties($propertiesFilePath){
    $properties = ConvertFrom-StringData (Get-Content -Path $propertiesFilePath -raw -ErrorAction Stop)
    return $properties
}
Function SendRawDataToLogAnalytics($propertiesFilePath, $jsonFilePath){
    $properties = LoadProperties -propertiesFilePath $propertiesFilePath
    $body = Get-Content -Path $jsonFilePath -ErrorAction Stop
    $statusCode = PostLogAnalyticsData -customerId $properties."workbooks.workbooksID" `
                            -sharedKey $properties."workbooks.sharedKey" `
                            -body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
                            -logType $properties."workbooks.logType"
    return $statusCode
}


Export-ModuleMember -Function *