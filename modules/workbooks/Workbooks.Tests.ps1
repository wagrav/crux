Import-Module $PSScriptRoot\Workbooks.psm1

$script:testDir = 'test_data'

Describe "Data Conversion tests" {
    BeforeAll {

    }
    AfterEach {
        Write-Host "Cleaning temporary test data"
        try
        {
            Remove-Item  "$PSScriptRoot\$script:testDir\data.json"
        }catch{

        }
    }
    Context 'Jmeter-CSV-Results-To-JSON ' {
        It "Jmeter-CSV-Results-To-JSON Should produce JSON file"  {
            Jmeter-CSV-Results-To-JSON "$PSScriptRoot\$script:testDir\data.csv" "$PSScriptRoot\$script:testDir\data.json"
            "$PSScriptRoot\$script:testDir\data.json" | Should -Exist
        }
        It "Jmeter-CSV-Results-To-JSON Should produce valid output"  {
            Jmeter-CSV-Results-To-JSON "$PSScriptRoot\$script:testDir\data.csv" "$PSScriptRoot\$script:testDir\data.json"
            $expected = Get-Content -Path "$PSScriptRoot\$script:testDir\data_expected_output.json"
            $actual = Get-Content -Path "$PSScriptRoot\$script:testDir\data.json"
            $actual | Should -Be $expected
        }
    }
}
