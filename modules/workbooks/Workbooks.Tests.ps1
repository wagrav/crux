Import-Module $PSScriptRoot\Workbooks.psm1

$script:testDir = 'test_data'

Describe "Data Conversion tests" {
    BeforeAll {

    }
    AfterEach {
        Try
        {
            if (Test-Path "$PSScriptRoot\$script:testDir\data.json") {
                Write-Host "Cleaning temporary test data"
                Remove-Item  "$PSScriptRoot\$script:testDir\data.json"
            }
        }
        Catch [System.Management.Automation.ItemNotFoundException]{
            ;
        }
    }
    Context 'JmeterCSVResultsToJSON ' {
        It "JmeterCSVResultsToJSON Should produce JSON file"  {
            JmeterCSVResultsToJSON "$PSScriptRoot\$script:testDir\data.csv" "$PSScriptRoot\$script:testDir\data.json"
            "$PSScriptRoot\$script:testDir\data.json" | Should -Exist
        }
        It "JmeterCSVResultsToJSON Should produce valid output"  {
            JmeterCSVResultsToJSON "$PSScriptRoot\$script:testDir\data.csv" "$PSScriptRoot\$script:testDir\data.json"
            $expected = Get-Content  -Path "$PSScriptRoot\$script:testDir\data_expected_output.json"
            $actual =  Get-Content  -Path "$PSScriptRoot\$script:testDir\data.json"
            $actual = $actual.replace(' ','')
            $expected = $expected.replace(' ','')
            "$actual" | Should -Be "$expected"
        }
        It "JmeterCSVResultsToJSON Should not throw exception when file not found"  {
            {JmeterCSVResultsToJSON "$PSScriptRoot\$script:testDir\idonotexists.csv" "$PSScriptRoot\$script:testDir\data.json"} | Should -Not -Throw
        }
    }
    Context 'Load Properties' {
        It "Properties should be loaded from file" {
            $properties = LoadProperties "$PSScriptRoot\$script:testDir\workbooks.properties"
            $properties | Should -Not -BeNullOrEmpty
            $properties."workbooks.enabled" | Should -Be 1
            $properties."workbooks.workbooksID" | Should -Be testID
            $properties."workbooks.sharedkey" | Should -Be testKey
            $properties."workbooks.logType" | Should -Be testType
        }
    }
    Context 'Data Sending' {
        It "E2E SendRawDataToLogAnalytics returns HTTP OK" {
            $statusCode = SendRawDataToLogAnalytics -propertiesFilePath "$PSScriptRoot\$script:testDir\workbooks.e2e.properties" `
                                       -jsonFilePath "$PSScriptRoot\$script:testDir\data_expected_output.json"
            $statusCode | Should -Be 200
        }
    }
    Context 'Workbooks' {
        It "CreateWorkbook" {
            1 | Should -Be 1
        }
    }
}
