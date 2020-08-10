function Get-IsSkipped {
    Start-Sleep -Second 1
    $false
}

function Get-IsSkippedNot {
    Start-Sleep -Second 1
    $true
}

Export-ModuleMember -Function Get-IsSkipped