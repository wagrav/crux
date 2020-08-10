function Get-IsSkipped {
    Start-Sleep -Second 1
    $false
}
$isSkipped = Get-IsSkipped

Describe "d" {
    It "i" -Skip:$isSkipped {

    }
}
