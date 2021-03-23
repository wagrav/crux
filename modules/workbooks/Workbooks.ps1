param(
      $PropertiesPath="$PSScriptRoot\test_data\workbooks.e2e.properties",
      #$FilePathCSV="$PSScriptRoot\test_data\data.csv",
      $FilePathCSV="$PSScriptRoot\test_data\1k_rows_data.csv",
      $OutFilePathCSV="$PSScriptRoot\test_data\out_data.csv",
      $DryRun=$false,
      $JmeterArg = 'dummy args',
      $BuildId = 'local',
      $BuildStatus = 'unknown',
      $PipelineId = 'local',
      $ByRows=10000,
      $AzurePostLimitMB=30,
      $UsePropertiesFile='true',
      $WorkbooksId='5cdf4a28-f1bf-4e59-ad01-2498e37059e9',
      $SharedKey='2tROkttxLKAPZA/7WkEx4P+0GOhZ7BkWzIp0OublY/h6I8x4/iL3R2aNWFx7YAT6bAHR4OKpt8ujAN7a1cL7lg==',
      $LogType='somelogtype'
)

Import-Module $PSScriptRoot\Workbooks.psm1 -Force

function Send-JMeterDataToLogAnalytics($FilePathCSV, $WorkbooksId, $SharedKey, $LogType)
{
    $status = 999
    $filePathJSON = "$PSScriptRoot/test_data/results.json"
    try
    {

        $status = Send-DataToLogAnalytics `
                        -FilePathCSV "$FilePathCSV" `
                        -FilePathJSON "$filePathJSON" `
                        -WorkbooksId $WorkbooksId `
                        -SharedKey $SharedKey `
                        -LogType $LogType

    }catch {
        Write-Host $_
    } finally {
        Write-Host ""
        Write-Host " - Data sent with HTTP status $status"
        Write-Host " - filePathJSON $filePathJSON"
    }
    return $status
}
function Split-File($FilePathCSV,[long]$ByRows=1000){
    $files=@() #return list of files for upload to analytics
    try
    {
        $startrow = 0;
        $counter = 1;
        Get-Content $FilePathCSV -read 1000 | % { $totalRows += $_.Length } #efficient count of lines for large file
        $totalRows -= 1; #exclude header
        Write-Host "$( $FilePathCSV | Split-Path -Leaf ) File has $totalRows lines"

        while ($startrow -lt $totalRows)
        {
            try
            {
                $partialFile = "$FilePathCSV$( $counter )"
                Write-Host "Splitting file $( $FilePathCSV | Split-Path -Leaf ) by $ByRows part $counter as $( $partialFile | Split-Path -Leaf )"
                Import-CSV $FilePathCSV | select-object -skip $startrow -first $ByRows | Export-CSV "$partialFile" -NoTypeInformation
                $startrow += $ByRows;
                $counter++;
                $files += $partialFile
            }
            catch
            {
                Write-Host $_
            }
        }
    }catch{
        Write-Host $_
    }
    return $files
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
    $sourceSizeMB = ((Get-Item $FilePathCSV).length/1MB)
    Write-Host "File {0} size {1:n3} Megs" -f $FilePathCSV,$sourceSizeMB
    Set-Variable AZURE_POST_LIMIT -option Constant -value $AzurePostLimitMB
    $files = Split-File -filePathCSV $FilePathCSV -ByRows $ByRows
    foreach($file in $files)
    {
        $OutFilePathCSV = "${file}_out"
        Add-MetaDataToCSV -filePathCSV $file -outFilePathCSV $OutFilePathCSV
        $sizeMB = ((Get-Item $OutFilePathCSV).length/1MB)
        Write-Host "Output file {0} has {0:n3} Megs" -f $OutFilePathCSV, $sizeMB
        if ($sizeMB -gt $AZURE_POST_LIMIT)
        {
            Write-Error "File $( $OutFilePathCSV | Split-Path -Leaf ) size exceeds limit of $AZURE_POST_LIMIT Megs: $sizeMB Megs" -ErrorAction Stop
        }
        if (-Not $DryRun)
        {
            Write-Host "Uploading file with size {0:n3} MB" -f $sizeMB
            if($UsePropertiesFile -eq "true")
            {
                $properties = Read-Properties -propertiesFilePath $PropertiesPath
                Write-Host "Using properties file $PropertiesPath for the upload"
                $status = Send-JMeterDataToLogAnalytics `
                            -filePathCSV "$OutFilePathCSV" `
                            -WorkbooksId $properties."workbooks.workbooksID" `
                            -SharedKey $properties."workbooks.sharedKey" `
                            -LogType $properties."workbooks.logType"
            }else{
                Write-Host "Reading WorkbooksId: $WorkbooksId, SharedKey: ***** and LogType: $LogType from parameters"
                $status = Send-JMeterDataToLogAnalytics `
                            -filePathCSV "$OutFilePathCSV" `
                            -WorkbooksId $WorkbooksId `
                            -SharedKey $SharedKey `
                            -LogType $LogType
            }
        }
        else
        {
            $status = 200
            Write-Host "Data Upload Mocked"
        }
        if ("$status" -ne "200")
        {
            Write-Error "Data has not been uploaded $status" -ErrorAction Stop
        }
    }
}
Start-Script