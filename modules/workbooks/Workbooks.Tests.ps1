Import-Module $PSScriptRoot\Workbooks.psm1

$script:testDir = 'test_data'

Describe "Data Conversion tests" {
    BeforeAll {

    }
    AfterEach {
        Write-Host "Cleaning temporary test data"
        Try
        {
            if (Test-Path "$PSScriptRoot\$script:testDir\data.json") {
                Remove-Item  "$PSScriptRoot\$script:testDir\data.json"
            }
        }
        Catch [System.Management.Automation.ItemNotFoundException]{
            ;
        }
    }
    Context 'Jmeter-CSV-Results-To-JSON ' {
        It "Jmeter-CSV-Results-To-JSON Should produce JSON file"  {
            Jmeter-CSV-Results-To-JSON "$PSScriptRoot\$script:testDir\data.csv" "$PSScriptRoot\$script:testDir\data.json"
            "$PSScriptRoot\$script:testDir\data.json" | Should -Exist
        }
        It "Jmeter-CSV-Results-To-JSON Should produce valid output"  {
            Jmeter-CSV-Results-To-JSON "$PSScriptRoot\$script:testDir\data.csv" "$PSScriptRoot\$script:testDir\data.json"
            $expected = Get-Content  -Path "$PSScriptRoot\$script:testDir\data_expected_output.json"
            $actual =  Get-Content  -Path "$PSScriptRoot\$script:testDir\data.json"
            $actual = $actual.replace(' ','')
            $expected = $expected.replace(' ','')
            "$actual" | Should -Be "$expected"
        }
        It "Jmeter-CSV-Results-To-JSON Should not throw exception when file not found"  {
            {Jmeter-CSV-Results-To-JSON "$PSScriptRoot\$script:testDir\idonotexists.csv" "$PSScriptRoot\$script:testDir\data.json"} | Should -Not -Throw
        }
    }
}
