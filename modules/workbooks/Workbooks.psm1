Function Jmeter-CSV-Results-To-JSON($FilePathCSV, $FilePathJSON)
{
    try
    {
        $x = Get-Content -Path $FilePathCSV -ErrorAction Stop
        $x = $x | ConvertFrom-Csv | ConvertTo-Json | Out-File -Encoding UTF8 $FilePathJSON
    }catch [System.Management.Automation.ItemNotFoundException] {
        "IO Error while rading/writng file: {0},{1}" -f $FilePathCSV, $FilePathJSON
        "Terminating"
    }
}

Export-ModuleMember -Function Jmeter-CSV-Results-To-JSON