$env=$args[0]
"running on: $env"
"current location: $(Get-Location)"
"script root: $PSScriptRoot"
"retrieve available modules"


if($env -contains 'azure'){ #pester 5.X syntax
    #workbook module
    Invoke-Pester -Script @{Path="$PSScriptRoot\..\workbooks\Workbooks.Tests.ps1"} -CodeCoverage @{Path="$PSScriptRoot\..\workbooks\*.ps1"}  -OutputFile $PSScriptRoot\results\workbook-pesterTEST.xml -OutputFormat 'NUnitXML'

}else{ #local pester 3.4.0 syntax
    $modules = Get-Module -list
    if ($modules.Name -notcontains 'pester') {
        Install-Module -Name Pester -Force -SkipPublisherCheck -RequiredVersion 3.4.0
    }
    #workbook module
    Invoke-Pester -Script "$PSScriptRoot\..\workbooks\Workbooks.Tests.ps1" -CodeCoverage "$PSScriptRoot\..\workbooks\*.ps1"  -OutputFile $PSScriptRoot\results\workbook-pesterTEST.xml -OutputFormat 'NUnitXML'
}


