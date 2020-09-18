Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

#region Get StartTime
function getStartTime ([int] $minutesToAdd) {
    $StartTime = (Get-Date).AddMinutes($minutesToAdd).ToString("yyyy-MM-ddTHH:mm:ssZ")
    Write-Host "Remember to create StartTime output variable"
    Write-Host "##vso[task.setvariable variable=StartTime;isOutput=true]$StartTime"
    return $StartTime
}
#endregion 

#region Get EndTime and after test actions
function getEndTime ([int] $minutesToAdd) {
    $EndTime = (Get-Date).AddMinutes($minutesToAdd).ToString("yyyy-MM-ddTHH:mm:ssZ")
    Write-Host "Remember to create EndTime output variable"
    Write-Host "##vso[task.setvariable variable=EndTime;isOutput=true]$EndTime"
    return $EndTime
}
#endregion

#region Config funciton 
function createConfig([string] $location, [string] $conf) {

    Set-Location $location
    $config_folder = "./config/"
    if (-not (Test-Path $config_folder)) { 
        New-Item -ItemType Directory -Force -Path $config_folder
    }
    $conf_res = $conf | ConvertFrom-Json     
    Write-Host "Result folder: $($conf_res.ResultFolder)" 
    
    $conf_res | ConvertTo-Json -Depth 100 | Out-File './config/config.json' 
    
    Write-Host "------------------ config.json ---------------------"    
    #Get-Content  './config/config.json'
}
#endregion

function establishAzContextAsCurrentUser() {
    Connect-AzAccount 
}
function establishAzContextAsSPN($tenantId, $spnid, $pwd) {
    $passwd = ConvertTo-SecureString $pwd -AsPlainText -Force
    $pscredential = New-Object System.Management.Automation.PSCredential($spnid, $passwd)    
    Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId
}

#region Get Data and convert into TSV

function convertJmeterXMLtoCSV([string]$fileTMP, [string]$fileName) {

    [System.Collections.ArrayList]$FinRes = @{ }                
            
    [xml]$XmlDocument = Get-Content $fileTMP
    $XmlDocument
    foreach ($sample in $XmlDocument.ChildNodes[1].SelectNodes("sample")) {
        #$sample
        $TG_ts = $sample.ts
        $TG_tn = $sample.tn
        $TG_lb = $sample.lb
        $TG_rm = $sample.rm
        $TG_hm = $sample.hn
        foreach ($httpSample in $sample.SelectNodes("httpSample")) {
            $obj = New-Object -TypeName psobject  

            $obj | Add-Member -NotePropertyName "TG_ts"  -NotePropertyValue $TG_ts
            $obj | Add-Member -NotePropertyName "TG_tn"  -NotePropertyValue $TG_tn
            $obj | Add-Member -NotePropertyName "TG_lb"  -NotePropertyValue $TG_lb
            $obj | Add-Member -NotePropertyName "TG_rm"  -NotePropertyValue $TG_rm
            $obj | Add-Member -NotePropertyName "TG_hm"  -NotePropertyValue $TG_hm

            $obj | Add-Member -NotePropertyName "timeStamp"  -NotePropertyValue $httpSample.ts
            $obj | Add-Member -NotePropertyName "rc"  -NotePropertyValue $httpSample.rc
            $obj | Add-Member -NotePropertyName "rm"  -NotePropertyValue $httpSample.rm
            $obj | Add-Member -NotePropertyName "ThreadGroup"  -NotePropertyValue $httpSample.tn
            #$obj | Add-Member -NotePropertyName "hostName"  -NotePropertyValue $httpSample.hn
            $obj | Add-Member -NotePropertyName "lb"  -NotePropertyValue $httpSample.lb
            $obj | Add-Member -NotePropertyName "url"  -NotePropertyValue $httpSample.'java.net.URL'
            $obj | Add-Member -NotePropertyName "responseHeader"  -NotePropertyValue $httpSample.responseHeader.InnerXml.Replace("`r`n", ' <\rn> ').Replace("`n", ' <\n> ').Replace("`r", ' <\r> ')
            $obj | Add-Member -NotePropertyName "requestHeader"  -NotePropertyValue $httpSample.requestHeader.InnerXml.Replace("`r`n", ' <\rn> ').Replace("`n", ' <\n> ').Replace("`r", ' <\r> ')
            $obj | Add-Member -NotePropertyName "responseData"  -NotePropertyValue $httpSample.responseData.InnerXml.Replace("`r`n", ' <\rn> ').Replace("`n", ' <\n> ').Replace("`r", ' <\r> ')
            $obj | Add-Member -NotePropertyName "cookies"  -NotePropertyValue $httpSample.cookies.InnerXml.Replace("`r`n", ' <\rn> ').Replace("`n", ' <\n> ').Replace("`r", ' <\r> ')
            $obj | Add-Member -NotePropertyName "method"  -NotePropertyValue $httpSample.method.InnerXml.Replace("`r`n", ' <\rn> ').Replace("`n", ' <\n> ').Replace("`r", ' <\r> ')
            $obj | Add-Member -NotePropertyName "queryString"  -NotePropertyValue $httpSample.queryString.InnerXml.Replace("`r`n", ' <\rn> ').Replace("`n", ' <\n> ').Replace("`r", ' <\r> ')
            #$httpSample
            #$obj
            $null = $FinRes.add($obj)
        }                            
    }
    if ($FinRes.Count -gt 0) {
        $FinRes | ConvertTo-Csv -NoTypeInformation > $fileName
        #Invoke-Item $fileName
    }
}
function ReplaceTokensWithValues([string]$stringToReplace, $StartDate, $EndDate) {
    $tmp = $stringToReplace
    $tmp = $tmp.Replace("***StartDate***", ([DateTime]$StartDate).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))
    $tmp = $tmp.Replace("***EndDate***", ([DateTime]$EndDate).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))
    return $tmp    
}
Function AdjustUrl ($url, $StartDate, $EndDate) {
    $url_req = $url
    if ($url.Contains("&timespan")) {    
        $url_req = ReplaceTokensWithValues $url_req $StartDate $EndDate
    }
    else {
        $timeSpan = ([DateTime]$StartDate).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") + "/" + ([DateTime]$EndDate).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $url_req += "&timespan=" + $timeSpan #can be encoded if needed [System.Web.HttpUtility]::UrlEncode($timeSpan)                        
    }
    if (!$url.Contains("&interval")) {                    
        $url_req += "&interval=PT1M"
    }
    return $url_req
}

function GetResultFileName ([string]$resultFolder, [string]$tableName, [string]$extention) {     
    return "$resultFolder/$($tableName)__$(Get-Date -Format hhmmssff)$extention"     
}

function convertDownloadSourceData([string] $location) {
    
    Set-Location $location    
    $config = Get-Content './config/config.json' | Out-String | ConvertFrom-Json 

    Write-Host "Result folder: $($Config.ResultFolder)"
    if (-not (Test-Path "$($Config.ResultFolder)")) { 
        New-Item -ItemType Directory -Force -Path "$($Config.ResultFolder)"
    }
    Remove-Item "$($Config.ResultFolder)/*.tsv"
    Remove-Item "$($Config.ResultFolder)/*.json"
    Remove-Item "$($Config.ResultFolder)/*.tmp"


    foreach ($configItem in $config.ActionTypes) {
   
        $context = Get-AzContext 
        $token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://management.core.windows.net/")
        $authHeader = @{
            'Content-Type'  = 'application/json'
            'Accept'        = 'application/json'
            'Authorization' = "Bearer $($token.AccessToken)"
        }

        $configItem.ActionType
        $configItem.URLorPath
        $configItem.TableName
    
        #-1.Run
        if ($configItem.ActionType -eq 'Runs') {    
            $Runs = [pscustomobject]@{    
                StartDate = ([DateTime]$Config.StartDate).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                EndDate   = ([DateTime]$Config.EndDate).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                Run       = $Config.Run
            }
            foreach ($c in $configItem.AddColumns.psobject.Properties) {
                $Runs | Add-Member -NotePropertyName $c.Name -NotePropertyValue $c.Value                       
            }
            $ResultFile = GetResultFileName $Config.ResultFolder $configItem.TableName ".tsv"
            $Runs | ConvertTo-Csv -NoTypeInformation | Out-File $ResultFile
        }

        #0.JmeterResult
        if ($configItem.ActionType -eq 'JmeterResult') {  
            foreach ($path in  $configItem.URLorPath) {
                # Get all files from directory
                foreach ($file in Get-ChildItem $path) {         
                
                    # Convert the file 
                    $file.FullName
                    # -ReadCount only for speed
                    [array]$csv = $null
                    [array]$csv = Get-Content $file.FullName -ReadCount 5000 | Foreach-Object { $_ } | ConvertFrom-Csv 
                    foreach ($csvLine in $csv) {
                        #Add additional columns
                        $csvLine | Add-Member -NotePropertyName Run -NotePropertyValue $config.Run
                        if ([bool]$configItem.psobject.Properties['AddColumns']) {  
                            foreach ($c in $configItem.AddColumns.psobject.Properties) {
                                $csvLine | Add-Member -NotePropertyName $c.Name -NotePropertyValue $c.Value                       
                            }
                        }
                        # $csvLine | Add-Member -NotePropertyName TimeFromBegining -NotePropertyValue (([DateTime]$csvLine.$DateTimeColumn - [DateTime]$config.StartDate)).TotalSeconds
                    }                                 
                    $ResultFileTMP = GetResultFileName $Config.ResultFolder $configItem.TableName ".tmp"
                    Write-Host $ResultFileTMP
                    $csv | ConvertTo-Csv -NoTypeInformation  > $ResultFileTMP                           
                    #Invoke-Item  $ResultFileTMP

                    # Split the file
                    $Header = Get-Content $ResultFileTMP -First 1 
                    # -ReadCount to split the files               
                    $i = 0; Get-Content $ResultFileTMP -ReadCount 5000 | ForEach-Object { 
                        $i++; 
                        $ResultFile = GetResultFileName $Config.ResultFolder "$($configItem.TableName)__$i" ".tsv"
                        if ($i -ne 1) { $Header > $ResultFile }
                        $_ | Out-File -Append $ResultFile
                    }
                    # remove after splitting
                    Remove-Item $ResultFileTMP               
                }
            }
        } 
        
        #0.JmeterResultXML    

        if ($configItem.ActionType -eq 'JmeterResultXML') {  
            foreach ($path in  $configItem.URLorPath) {
                # Get all files from directory
                foreach ($file in Get-ChildItem $path) {         
                    $file.FullName
                    # -ReadCount only for speed           

                    $reader = new-object System.IO.StreamReader($file.FullName)                              

                    $ignoreAll = $false
                    $ignoreOne = $false 

                    $SampleCount = 0
                    $samleLevel = 0
                    [System.Collections.ArrayList]$FinRes = @{ }
                    $FinRes.Add('<?xml version="1.0" encoding="UTF-8"?>')
                    $FinRes.Add('<testResults>')

                    while ($null -ne ($line = $reader.ReadLine())) {
                        if ($line.Contains('<?xml version="')) { $ignoreOne = $true }
                        if ($line.Contains('<testResults version="')) { $ignoreOne = $true }
                        if ($line.Contains('</testResults>')) { $ignoreOne = $true } 

                        if ($line.Contains('<responseData class="java.lang.String">&#x89;PNG&#xd;')) {
                            $null = $FinRes.Add('<responseData class="java.lang.String"> PNG') 
                            $ignoreAll = $true
                        }
                    
                        if ($ignoreAll -and $line.contains('</responseData>')) {
                            $line = '</responseData>'
                            $ignoreAll = $false
                        }
                    
                        if ($line.Contains('<sample ')) { 
                            $samleLevel++                         
                            if ($samleLevel -gt 1) { $ignoreOne = $true }  # ignore intermediate samples
                        }
                        if ($line.Contains('</sample>')) { 
                            if ($samleLevel -eq 1) { $SampleCount++ }
                            if ($samleLevel -gt 1) { $ignoreOne = $true }  # ignore intermediate samples
                            $samleLevel-- 
                        }

                        # Add line
                        If ( $ignoreAll ) { $ignoreOne = $true }
                        if ( !$ignoreOne ) {    
                            $null = $FinRes.Add($line) 
                        }
                        $ignoreOne = $false 


                        if ($SampleCount -gt 10 -or $line.Contains('</testResults>')) {                        
                        
                            # finish and write the file
                            $FinRes.Add('</testResults>')
                            $ResultFileTMP = GetResultFileName $Config.ResultFolder $configItem.TableName ".tmp"                        
                            $FinRes> $ResultFileTMP

                            $ResultFile = GetResultFileName $Config.ResultFolder $configItem.TableName ".tsv"
                            convertJmeterXMLtoCSV $ResultFileTMP $ResultFile 

                            Remove-Item $ResultFileTMP
                            # reset counter and create new array for results
                            $SampleCount = 0                                               
                            [System.Collections.ArrayList]$FinRes = @{ }
                            $FinRes.Add('<?xml version="1.0" encoding="UTF-8"?>')
                            $FinRes.Add('<testResults>') 
                        }
 
                    }
                    $reader.Close()
                }
            }
            # Write-Error "Wywalka"  
        }     
    
        #1.AzMonMetric
        if ($configItem.ActionType -eq 'AzMonMetric') {                        
            foreach ($url in $configItem.URLorPath) {
                $result = $null
                $ResultFile = GetResultFileName $Config.ResultFolder $configItem.TableName ".tsv"

                $url_req = AdjustUrl $url $Config.StartDate $Config.EndDate
            
                try {
                    $result = Invoke-RestMethod -Method Get -Uri $url_req -Headers $authHeader  -Verbose
                }
                catch {                
                    Write-Warning $_.Exception.Message
                    Start-Sleep -Seconds 60             
                    $result = Invoke-RestMethod -Method Get -Uri $url_req -Headers $authHeader  -Verbose
                }
           
                $ex = $result.value[0].timeseries[0].data[0]
                if ($ex) {            
                    foreach ($m in $result.value[0].timeseries[0].data ) {
                        $m | Add-Member -NotePropertyName Run -NotePropertyValue $Config.Run
                        if ([bool]$configItem.psobject.Properties['AddColumns']) {  
                            foreach ($c in $configItem.AddColumns.psobject.Properties) {
                                $m | Add-Member -NotePropertyName $c.Name -NotePropertyValue $c.Value                       
                            }
                        }
                    }        
                    $null = $result.value[0].timeseries[0].data | ConvertTo-Csv -NoTypeInformation > $ResultFile               
                    #Invoke-Item $ResultFile
                }
            }       
        }

        #1.AzMonMetric2
        if ($configItem.ActionType -eq 'AzMonMetric2') {                        
            foreach ($url in $configItem.URLorPath) {
                [System.Collections.ArrayList]$FinRes = @{ }
                $result = $null
                $ResultFile = GetResultFileName $Config.ResultFolder $configItem.TableName ".tsv"

                $url_req = AdjustUrl $url $Config.StartDate $Config.EndDate

                try {
                    $result = Invoke-RestMethod -Method Get -Uri $url_req -Headers $authHeader  -Verbose     
                }
                catch {                
                    Write-Warning $_.Exception.Message
                    Start-Sleep -Seconds 60             
                    $result = Invoke-RestMethod -Method Get -Uri $url_req -Headers $authHeader  -Verbose                 
                }
           
                $metricName = $result.value[0].name.localizedValue
                foreach ($ts in $result.value[0].timeseries) {
                    if ($ts.metadatavalues.Count -gt 0) {
                        $dimName = $ts.metadatavalues[0].name.value
                        $dimValue = $ts.metadatavalues[0].value
                    } 
                    $ex = $ts.data[0]                
                    if ($ex) {            
                        foreach ($r in $ts.data ) {                       
                            $obj = New-Object -TypeName psobject                                                                 
                            $obj | Add-Member -NotePropertyName "MetricName"  -NotePropertyValue $metricName 
                            if ($ts.metadatavalues.Count -gt 0) {
                                $obj | Add-Member -NotePropertyName "DimentionName"  -NotePropertyValue $dimName 
                                $obj | Add-Member -NotePropertyName "DimentionValue"  -NotePropertyValue $dimValue             
                            }
                            foreach ($v in $r.psobject.Properties) {
                                $obj | Add-Member -NotePropertyName $v.Name  -NotePropertyValue $v.Value                
                            }                    
                            $obj | Add-Member -NotePropertyName Run -NotePropertyValue $config.Run
                            if ([bool]$configItem.psobject.Properties['AddColumns']) {  
                                foreach ($c in $configItem.AddColumns.psobject.Properties) {
                                    $obj | Add-Member -NotePropertyName $c.Name -NotePropertyValue $c.Value                       
                                }
                            } 
                            $null = $FinRes.add($obj)
                        }    
                    } 

                    if ($FinRes.Count -gt 0) {
                        $FinRes | ConvertTo-Csv -NoTypeInformation > $ResultFile
                        #Invoke-Item $ResultFile
                    }
                }
            }       
        }

        #2.AppInsMetric
        if ($configItem.ActionType -eq 'AppInsMetric') {               
            foreach ($url in $configItem.URLorPath) {
                [System.Collections.ArrayList]$FinRes = @{ }
                $result = $null
                $ResultFile = GetResultFileName $Config.ResultFolder $configItem.TableName ".tsv"
            
                $url_req = AdjustUrl $url $Config.StartDate $Config.EndDate

                try {
                    $result = invoke-RestMethod -Method Get -uri $url_req -Headers $authHeader  -Verbose  
                }
                catch {                
                    Write-Warning $_.Exception.Message
                    Start-Sleep -Seconds 60             
                    $result = invoke-RestMethod -Method Get -uri $url_req -Headers $authHeader  -Verbose  
                }

                if ($url_req.Contains("&segment")) {
                    foreach ($s in $result.value.segments ) {
                        foreach ($m in $s.segments ) {
                            $obj = New-Object -TypeName psobject
                            $obj | Add-Member -NotePropertyName "start"  -NotePropertyValue $s.start           
                            $obj | Add-Member -NotePropertyName "end"  -NotePropertyValue $s.end           
                            $obj | Add-Member -NotePropertyName "MetricName"  -NotePropertyValue $m.psobject.Properties.Name[0] 
                            $obj | Add-Member -NotePropertyName "SegmentName"  -NotePropertyValue $m.psobject.Properties.Name[1]             
                            foreach ($v in $m.psobject.Properties.Value[0].psobject.Properties) {
                                $obj | Add-Member -NotePropertyName $v.Name  -NotePropertyValue $v.Value                
                            }                    
                            $obj | Add-Member -NotePropertyName Run -NotePropertyValue $config.Run
                            if ([bool]$configItem.psobject.Properties['AddColumns']) {  
                                foreach ($c in $configItem.AddColumns.psobject.Properties) {
                                    $obj | Add-Member -NotePropertyName $c.Name -NotePropertyValue $c.Value                       
                                }
                            } 
                            $null = $FinRes.add($obj)
                            #$m
                        }
                    }

                }
                else {
                    foreach ($m in $result.value.segments ) {
                        $obj = New-Object -TypeName psobject
                        $obj | Add-Member -NotePropertyName "start"  -NotePropertyValue $m.start           
                        $obj | Add-Member -NotePropertyName "end"  -NotePropertyValue $m.end      
                        $obj | Add-Member -NotePropertyName "MetricName"  -NotePropertyValue $m.psobject.Properties.Name[2]  

                        foreach ($v in $m.psobject.Properties.Value[2].psobject.Properties) {
                            $obj | Add-Member -NotePropertyName $v.Name  -NotePropertyValue $v.Value                
                        }         
                
                        $obj | Add-Member -NotePropertyName Run -NotePropertyValue $config.Run
                        if ([bool]$configItem.psobject.Properties['AddColumns']) {  
                            foreach ($c in $configItem.AddColumns.psobject.Properties) {
                                $obj | Add-Member -NotePropertyName $c.Name -NotePropertyValue $c.Value                       
                            }
                        }  
                        $null = $FinRes.add($obj)
                    }            
                }
                if ($FinRes.Count -gt 0) {
                    $FinRes | ConvertTo-Csv -NoTypeInformation > $ResultFile
                    #Invoke-Item $ResultFile
                }
            }  
        }

        #3.AppInsQuery
        if ($configItem.ActionType -eq 'AppInsQuery') {               
        
            [System.Collections.ArrayList]$FinRes = @{ }
            $result = $null        
            $ResultFile = GetResultFileName $Config.ResultFolder $configItem.TableName ".tsv"

            $url_req = AdjustUrl $configItem.URLorPath $Config.StartDate $Config.EndDate        
            $logQuery = ReplaceTokensWithValues $configItem.Query $Config.StartDate $Config.EndDate 

            $logQueryBody = @{"query" = $logQuery } | convertTo-Json
                
            try {
                $result = invoke-RestMethod -method POST -uri $url_req -Headers $authHeader -Body $logQueryBody
            }
            catch {                
                Write-Warning $_.Exception.Message
                Start-Sleep -Seconds 60             
                $result = invoke-RestMethod -method POST -uri $url_req -Headers $authHeader -Body $logQueryBody
            }
        
            foreach ($r in $result.Tables[0].Rows ) {
                $obj = New-Object -TypeName psobject
                for ($i = 0; $i -lt $result.Tables[0].Columns.Count; $i++) {                
                    $obj | Add-Member -NotePropertyName $result.Tables[0].Columns[$i].ColumnName  -NotePropertyValue $r[$i]          
                }
                $obj | Add-Member -NotePropertyName Run -NotePropertyValue $config.Run 
                if ([bool]$configItem.psobject.Properties['AddColumns']) {  
                    foreach ($c in $configItem.AddColumns.psobject.Properties) {
                        $obj | Add-Member -NotePropertyName $c.Name -NotePropertyValue $c.Value                       
                    }
                } 
                $null = $FinRes.add($obj)
            }            
    
            if ($FinRes.Count -gt 0) {
                $FinRes | ConvertTo-Csv -NoTypeInformation > $ResultFile  
                # Invoke-Item > $ResultFile  
            }
        }  

        #4.LogAnalQuery
        if ($configItem.ActionType -eq 'LogAnalQuery') {    
       
            [System.Collections.ArrayList]$FinRes = @{ }
            $result = $null
            $ResultFile = GetResultFileName $Config.ResultFolder $configItem.TableName ".tsv"

            $url_req = AdjustUrl $configItem.URLorPath $Config.StartDate $Config.EndDate
            $logQuery = ReplaceTokensWithValues $configItem.Query $Config.StartDate $Config.EndDate 

            $logQueryBody = @{"query" = $logQuery } | convertTo-Json            

            try {
                $result = invoke-RestMethod -method POST -uri $url_req -Headers $authHeader -Body $logQueryBody    
            }
            catch {                
                Write-Warning $_.Exception.Message
                Start-Sleep -Seconds 60             
                $result = invoke-RestMethod -method POST -uri $url_req -Headers $authHeader -Body $logQueryBody    
            }  
        
            foreach ($r in $result.Tables[0].Rows ) {
                $obj = New-Object -TypeName psobject
                for ($i = 0; $i -lt $result.Tables[0].Columns.Count; $i++) {                
                    $obj | Add-Member -NotePropertyName $result.Tables[0].Columns[$i].name  -NotePropertyValue $r[$i]          
                }
                $obj | Add-Member -NotePropertyName Run -NotePropertyValue $config.Run 
                if ([bool]$configItem.psobject.Properties['AddColumns']) {  
                    foreach ($c in $configItem.AddColumns.psobject.Properties) {
                        $obj | Add-Member -NotePropertyName $c.Name -NotePropertyValue $c.Value                       
                    }
                } 
                $null = $FinRes.add($obj)
            }            
    
            if ($FinRes.Count -gt 0) {
                $FinRes | ConvertTo-Csv -NoTypeInformation > $ResultFile                        
                #Invoke-Item $ResultFile
            }
        }
    }
}


#region Upload files into LogAnalyticWorkspace
  
# Create the function to create the authorization signature
Function CreateSignature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource
 
    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)
 
    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
    return $authorization
}

# Create the function to create and post the request
Function uploadToLogAnalytics($customerId, $sharedKey, $body, $logType, $TimeStampField) {
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = CreateSignature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
 
    $headers = @{
        "Authorization" = $signature;
        "Log-Type"      = $logType;
        "x-ms-date"     = $rfc1123date;
        #       "time-generated-field" = $TimeStampField;
    }
 
    try {
        $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    }
    catch {                
        Write-Warning $_.Exception.Message
        Start-Sleep -Seconds 60             
        $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    }

    return $response.StatusCode
 
}

function uplaodSourceDataIntoLogAnalytics([string] $location, $customerId, $sharedKey) {
    
    Set-Location $location    
    $config = Get-Content './config/config.json' | Out-String | ConvertFrom-Json 
    Remove-Item "$($Config.ResultFolder)/*.json"

    foreach ($file in Get-ChildItem "$($Config.ResultFolder)/*.tsv" ) {
    
        Write-Host "Processing file: $file"  
        #$contentCSV = Get-Content $file | ConvertFrom-Csv 
        [array]$contentCSV = Import-Csv -Path $file 

        if ($contentCSV.Count -gt 0) {
            $columnDataTypes = @{ }
            # Get destination format form config
            $filePart = $file.BaseName.Split("__")[0]
            if ($columnDataTypes.Count -eq 0) {
                foreach ($f in $Config.UploadSpec) {
                    if ($f.TableName -eq $filePart) {
                        foreach ($p in $f.ColumnsDataType.psobject.Properties) {
                            if ($contentCSV[0].psobject.Properties.Name -contains $p.Name) {
                                #add only if exists on fist row.
                                $columnDataTypes[$p.Name] = $p.Value
                            }
                            else {
                                Write-Host "Column $($p.Name) with datatype $($p.Value) ignored"
                            }
                        }
                    }
                }
            } 
    
            foreach ($row in  $contentCSV) {               
                foreach ($cdt in $columnDataTypes.GetEnumerator()) {
                    $ooo = $cdt.Key
                    $row.$ooo = $row.$ooo -as $cdt.Value           
                }  
            }    
        }
    
        $json = $contentCSV | ConvertTo-Json 
        #if ($contentCSV.count -lt 2) { $json = "[ " + $json + " ]" }
        $json > "$($Config.ResultFolder)/$($file.BaseName).json" 
        #Invoke-Item "$($Config.ResultFolder)/$($file.BaseName).json"

        Write-Host "Data will be sent for file: $($file.BaseName) FilePart: $filePart" 
        # Submit the data to the API endpoint
        UploadToLogAnalytics -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $filePart -TimeStampField "timeStamp" 

    }  
}
#endregion

