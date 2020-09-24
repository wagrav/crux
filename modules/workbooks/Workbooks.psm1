Import-Module $PSScriptRoot\Azure.psm1

Function JmeterCSVResultsToJSON($filePathCSV, $filePathJSON)
{
    try
    {
        $csv = Get-Content -Path $filePathCSV -ErrorAction Stop
        $csv = $csv | ConvertFrom-Csv | ConvertTo-Json | Out-File -Encoding UTF8 $filePathJSON
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
Function SendRawDataToLogAnalytics($propertiesFilePath, $filePathJSON){

    $properties = LoadProperties -propertiesFilePath $propertiesFilePath
    $body = Get-Content -Path $filePathJSON
    $statusCode = PostLogAnalyticsData -customerId $properties."workbooks.workbooksID" `
                            -sharedKey $properties."workbooks.sharedKey" `
                            -body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
                            -logType $properties."workbooks.logType"
    return $statusCode
}

Function AddColumnToCSV($filePathCSV, $outFilePathCSV, $columnHeader, $columnFieldsValue){
    Write-Host "$columnHeader -> $columnFieldsValue"
    Import-Csv $filePathCSV |
            Select-Object *,@{Name=$columnHeader;Expression={"$columnFieldsValue"}} |
            Export-Csv "$outFilePathCSV" -NoTypeInformation
}

Function SendDataToLogAnalytics($propertiesFilePath, $filePathCSV, $filePathJSON){
    $status = 999
    try
    {
        JmeterCSVResultsToJSON -filePathCSV $filePathCSV -filePathJSON $filePathJSON
        $status = SendRawDataToLogAnalytics -propertiesFilePath $propertiesFilePath -filePathJSON $filePathJSON
    }catch {
        Write-Host "Unexpected exception"
        Write-Host $_
        Write-Host $_.ScriptStackTrace
    }
    return $status
}


Export-ModuleMember -Function *