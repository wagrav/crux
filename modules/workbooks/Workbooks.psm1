Import-Module $PSScriptRoot\Azure.psm1

function ConvertJmeterCSVResultsToJSON($FilePathCSV, $FilePathJSON)
{
    try
    {
        $csv = Get-Content -Path $FilePathCSV -ErrorAction Stop
        $csv = $csv | ConvertFrom-Csv | ConvertTo-Json | Out-File -Encoding UTF8 $FilePathJSON
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
        "IO Error while rading/writing file: {0},{1}" -f $FilePathCSV, $FilePathJSON
        "Terminating"
    }
}

function LoadProperties($PropertiesFilePath)
{
    $properties = ConvertFrom-StringData (Get-Content -Path $PropertiesFilePath -raw -ErrorAction Stop)
    return $properties
}
function SendRawDataToLogAnalytics($PropertiesFilePath, $FilePathJSON)
{

    $properties = LoadProperties -propertiesFilePath $PropertiesFilePath
    $body = Get-Content -Path $FilePathJSON
    $statusCode = PostLogAnalyticsData -customerId $properties."workbooks.workbooksID" `
                            -sharedKey $properties."workbooks.sharedKey" `
                            -body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
                            -logType $properties."workbooks.logType"
    return $statusCode
}

function AddColumnToCSV($FilePathCSV, $OutFilePathCSV, $ColumnHeader, $ColumnFieldsValue)
{
    Write-Host "$ColumnHeader -> $ColumnFieldsValue"
    Import-Csv $FilePathCSV |
            Select-Object *, @{ Name = $ColumnHeader; Expression = { "$ColumnFieldsValue" } } |
            Export-Csv "$OutFilePathCSV" -NoTypeInformation
}

function SendDataToLogAnalytics($PropertiesFilePath, $FilePathCSV, $FilePathJSON)
{
    $status = 999
    try
    {
        ConvertJmeterCSVResultsToJSON -filePathCSV $FilePathCSV -filePathJSON $FilePathJSON
        $status = SendRawDataToLogAnalytics -propertiesFilePath $PropertiesFilePath -filePathJSON $FilePathJSON
    }
    catch
    {
        Write-Host "Unexpected exception"
        Write-Host $_
        Write-Host $_.ScriptStackTrace
    }
    return $status
}


Export-ModuleMember -function *