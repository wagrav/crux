function Get-IsSkipped {
    Start-Sleep -Second 1
    $false
}
$isSkipped = Get-IsSkipped

Describe "Sample test" {
    It "Sample test" -Skip:$isSkipped {

    }
}
