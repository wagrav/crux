# This is only an example and default configuration for test purposes
# Important: !!!! This should be overwriten by application specific file in CI/CD pipeline !!!!

function getConfigBody([String] $Run, [string] $StartDate, [string] $EndDate, [string] $jmeterResultFolder, [string] $jmeterResultFolderXML)
{
Write-Host "Run: $Run (StartDate: $StartDate : EndDate: $EndDate) " 

$jmeterResultFolder = $jmeterResultFolder.Replace('\', '\\')
$jmeterResultFolderXML = $jmeterResultFolderXML.Replace('\', '\\')
$convertedResultFolder = ".\results".Replace('\', '\\')

$filter = '$filter'

$conf = @"
{
    "StartDate":  "$StartDate",
    "EndDate":  "$EndDate",
    "Run":  "$Run",
    "ResultFolder":  "$convertedResultFolder",
    "ActionTypes":  [
                        {
                            "ActionType":  "Runs",
                            "TableName":  "RunXX",
                            "URLorPath": "",
                            "AddColumns":  {
                                            "Desc":  "run1",
                                            "Desc2":  "run2"
                                           }
                        },
                        {
                            "ActionType":  "JmeterResult",
                            "TableName":  "JmeterXX",
                            "URLorPath":  [
                                              "$jmeterResultFolder"
                                          ],
                            "AddColumns":  {
                                            "Desc":  "from jmeter file",
                                            "Desc2":  "from jmeter file2"
                                           }
                        },
                        {
                            "ActionType":  "JmeterResultXML",
                            "TableName":  "JmeterXML4",
                            "URLorPath":  [
                                              "$jmeterResultFolderXML"
                                          ],
                            "AddColumns":  {
                                            "Desc":  "from jmeter file",
                                            "Desc2":  "from jmeter file2"
                                           }
                        },
                        {
                            "ActionType":  "AzMonMetric2",
                            "TableName":  "PerfCountAppIns",
                            "URLorPath":  [
                                              "https://management.azure.com/subscriptions/d1c6a5c6-b110-44c3-b156-a4435667b1a9/resourceGroups/sampleapplication/providers/microsoft.insights/components/sampleappjgoappins/providers/microsoft.insights/metrics?api-version=2018-01-01&interval=PT1M&metricnames=performanceCounters/processCpuPercentage&timespan=***StartDate***/***EndDate***",
                                              "https://management.azure.com/subscriptions/d1c6a5c6-b110-44c3-b156-a4435667b1a9/resourceGroups/sampleapplication/providers/microsoft.insights/components/sampleappjgoappins/providers/microsoft.insights/metrics?api-version=2018-01-01&interval=PT1M&metricnames=performanceCounters/processCpuPercentage"
                                          ],
                            "AddColumns":  {
                                            "Desc":  "run1",
                                            "Desc2":  "run2"
                                            }
                        },
                        {
                            "ActionType":  "AzMonMetric2",
                            "TableName":  "BlobDimensions",
                            "URLorPath":  [
                                              "https://management.azure.com/subscriptions/d1c6a5c6-b110-44c3-b156-a4435667b1a9/resourceGroups/cloud-shell-storage-westeurope/providers/Microsoft.Storage/storageAccounts/csbd1c6a5c6b110x44c3xb15/blobServices/default/providers/microsoft.Insights/metrics?api-version=2019-07-01&metricnames=BlobCapacity&aggregation=average&metricNamespace=microsoft.storage%2Fstorageaccounts%2Fblobservices&top=10&orderby=average desc&$filter=BlobType eq '*'&autoadjusttimegrain=true&validatedimensions=false&timespan=***StartDate***/***EndDate***",                                              
                                              "https://management.azure.com/subscriptions/d1c6a5c6-b110-44c3-b156-a4435667b1a9/resourceGroups/cloud-shell-storage-westeurope/providers/Microsoft.Storage/storageAccounts/csbd1c6a5c6b110x44c3xb15/blobServices/default/providers/microsoft.Insights/metrics?api-version=2019-07-01&metricnames=BlobCapacity&aggregation=average,count&metricNamespace=microsoft.storage%2Fstorageaccounts%2Fblobservices&top=10&orderby=average desc&$filter=BlobType eq '*'&autoadjusttimegrain=true&validatedimensions=false&timespan=***StartDate***/***EndDate***"
                                          ],
                            "AddColumns":  {
                                            "Desc":  "run1",
                                            "Desc2":  "run2"
                                            }
                        },
                        {
                            "ActionType":  "AzMonMetric",
                            "TableName":  "CPUforWebApp",
                            "URLorPath":  [
                                              "https://management.azure.com/subscriptions/d1c6a5c6-b110-44c3-b156-a4435667b1a9/resourceGroups/sampleapplication/providers/Microsoft.Web/sites/sampleappjgo/providers/microsoft.insights/metrics?api-version=2018-01-01&interval=PT1M&metricnames=CpuTime"
                                          ]                                          
                        },
                        {
                            "ActionType":  "AppInsMetric",
                            "TableName":  "AppInsMetric",
                            "URLorPath":  [
                                              "https://management.azure.com/subscriptions/d1c6a5c6-b110-44c3-b156-a4435667b1a9/resourceGroups/sampleapplication/providers/microsoft.insights/components/sampleappjgoappins/metrics/performanceCounters/processCpuPercentage?api-version=2018-04-20&aggregation=min,avg,count"
                                          ],
                        "AddColumns":  {
                                       "Desc":  "run1",
                                       "Desc2":  "run2"
                                       }
                        },
                        {
                            "ActionType":  "AppInsMetric",
                            "TableName":  "AppInsMetric2",
                            "URLorPath":  [
                                              "https://management.azure.com/subscriptions/d1c6a5c6-b110-44c3-b156-a4435667b1a9/resourceGroups/sampleapplication/providers/microsoft.insights/components/sampleappjgoappins/metrics/requests/count?api-version=2018-04-20&segment=request%2FurlPath"
                                          ]
                        },
                        {
                            "ActionType":  "AppInsQuery",
                            "TableName":  "AppInsQuery",
                            "URLorPath":  "https://management.azure.com/subscriptions/d1c6a5c6-b110-44c3-b156-a4435667b1a9/resourceGroups/sampleapplication/providers/microsoft.insights/components/sampleappjgoappins/api/query?api-version=2018-05-01-preview",
                            "Query":   "customMetrics | limit 50",
                            "AddColumns":  {
                                            "Desc":  "run1",
                                            "Desc2":  "run2"
                                            }
                        },
                        {
                            "ActionType":  "LogAnalQuery",
                            "TableName":  "LogAnalQuery",
                            "URLorPath":  "https://management.azure.com/subscriptions/d1c6a5c6-b110-44c3-b156-a4435667b1a9/resourceGroups/NewNew/providers/Microsoft.OperationalInsights/workspaces/LLLAW/query?api-version=2017-10-01&timespan=2019-10-08T12%3A08%3A38Z%2F2019-11-25T22%3A38%3A38Z",
                            "Query":   "AzureMetrics | where TimeGenerated < now() and TimeGenerated > ago(7m) | limit 1000",
                            "AddColumns":  {
                                            "Desc":  "run1",
                                            "Desc2":  "run2"
                                            }
                        },
                        {
                            "ActionType":  "LogAnalQuery_Ignore",
                            "TableName":  "LogAnalQuery1",
                            "URLorPath":  "https://management.azure.com/subscriptions/d1c6a5c6-b110-44c3-b156-a4435667b1a9/resourceGroups/NewNew/providers/Microsoft.OperationalInsights/workspaces/LLLAW/query?api-version=2017-10-01",
                            "Query":   "app(\"msitest11\").traces | where timestamp < ago(1s) and timestamp > ago(3m) "
                        },
                        {
                            "ActionType":  "LogAnalQuery_Ignore",
                            "TableName":  "LogAnalQuery2",
                            "URLorPath":  "https://management.azure.com/subscriptions/d1c6a5c6-b110-44c3-b156-a4435667b1a9/resourceGroups/NewNew/providers/Microsoft.OperationalInsights/workspaces/LLLAW/query?api-version=2017-10-01",
                            "Query":   "app(\"sampleappjgoappins\").performanceCounters | where timestamp > ago(1h) and name == \"% Processor Time\" and category == \"Process\" | summarize max(value) by bin(timestamp , 1m)"
                        }
                    ],
    "UploadSpec":  [
                       {
                           "TableName":  "JmeterXX",
                           "ColumnsDataType":  {
                                                   "elapsed":  "System.Int32",
                                                   "bytes":  "System.Int32",
                                                   "sentBytes":  "System.Int32",
                                                   "grpThreads":  "System.Int32",
                                                   "allThreads":  "System.Int32",
                                                   "Latency":  "System.Int32",
                                                   "IdleTime":  "System.Int32",
                                                   "Connect":  "System.Int32",
                                                   "TimeFromBegining":  "System.Single"
                                               }
                       }
                   ]
}
"@

return $conf

}