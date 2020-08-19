$env=$args[0]
"running on: $env"
"current location: $(Get-Location)"
"script root: $PSScriptRoot"
"retrieve available modules"

Invoke-Pester -Script "$PSScriptRoot\..\workbooks\Workbooks.Tests.ps1" -PassThru -CodeCoverageOutputFile $PSScriptRoot\results\workbook-pesterCoverageTEST.xml -CodeCoverage "$PSScriptRoot\..\workbooks\*.psm1"  -OutputFile $PSScriptRoot\results\workbook-pesterTEST.xml -OutputFormat 'NUnitXML'



