$env=$args[0]
"running on: $env"
"current location: $(Get-Location)"
"script root: $PSScriptRoot"
"retrieve available modules"


if($env -contains 'azure'){ #pester 5.X syntax
    #workbook module, support code coverage
    Invoke-Pester -Script "$PSScriptRoot\..\workbooks\Workbooks.Tests.ps1" -CodeCoverageOutputFile $PSScriptRoot\results\workbook-pesterCoverageTEST.xml -CodeCoverage "$PSScriptRoot\..\workbooks\*.ps1"  -OutputFile $PSScriptRoot\results\workbook-pesterTEST.xml -OutputFormat 'NUnitXML'
}else{ #local pester 3.4.0 syntax
    Invoke-Pester -Script "$PSScriptRoot\..\workbooks\Workbooks.Tests.ps1" -CodeCoverage "$PSScriptRoot\..\workbooks\*.ps1"  -OutputFile $PSScriptRoot\results\workbook-pesterTEST.xml -OutputFormat 'NUnitXML'
}


