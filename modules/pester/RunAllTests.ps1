$env=$args[0]
"running on: $env"
"current location: $(Get-Location)"
"script root: $PSScriptRoot"
"retrieve available modules"

#assures we all use teh same pester version
if($env -contains 'azure'){
    Get-InstalledModule -Name Pester | Uninstall-Module -Force  #uninstall default perester 5
    Install-Module -Name Pester -Force -SkipPublisherCheck -RequiredVersion 3.4.0 #install windows 10 pester
}else{
    $modules = Get-Module -list
    if ($modules.Name -notcontains 'pester') {
        Install-Module -Name Pester -Force -SkipPublisherCheck -RequiredVersion 3.4.0
    }
}
#workbook module
Invoke-Pester -Script "$PSScriptRoot\..\workbooks\Workbooks.Tests.ps1" -CodeCoverage "$PSScriptRoot\..\workbooks\*.ps1"  -OutputFile $PSScriptRoot\results\workbook-pesterTEST.xml -OutputFormat 'NUnitXML'


