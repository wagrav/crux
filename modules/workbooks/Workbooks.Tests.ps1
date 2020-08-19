Import-Module $PSScriptRoot\Workbooks.psm1

$isSkipped = Get-IsSkipped

Describe "Sample test" {
    It "Sample test" -Skip:$isSkipped {

    }
}
