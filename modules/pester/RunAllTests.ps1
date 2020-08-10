"current location: $(Get-Location)"
"script root: $PSScriptRoot"
"retrieve available modules"

$modules = Get-Module -list
if ($modules.Name -notcontains 'pester') {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}
Invoke-Pester -Script $PSScriptRoot\..\workbooks\Workbooks.Tests.ps1 -CodeCoverage $PSScriptRoot\..\workbooks\*.ps1 -OutputFile $PSScriptRoot\results\workbook-TEST.xml -OutputFormat 'NUnitXML'


