Import-Module $PSScriptRoot\Workbooks.psm1 -Force
$script:testDir = 'test_data'

Describe "Workbook tests" {
    BeforeAll {
        Write-Host "Running with powershell version" $PSVersionTable.PSVersion
    }
    Context 'When I try to convert non-existing file' {
        JmeterCSVResultsToJSON "$PSScriptRoot\$script:testDir\data.csv" "$PSScriptRoot\$script:testDir\data.json"
        It "should not throw exception"  {
            { JmeterCSVResultsToJSON "$PSScriptRoot\$script:testDir\idonotexists.csv" "$PSScriptRoot\$script:testDir\data.json" } | Should -Not -Throw
        }
    }
    Context 'When I convert JMETER CSV results' {
        AfterAll {
            Try
            {
                if (Test-Path "$PSScriptRoot\$script:testDir\data.json")
                {
                    Write-Host "Cleaning temporary test data"
                    Remove-Item  "$PSScriptRoot\$script:testDir\data.json"
                }
            }
            Catch [System.Management.Automation.ItemNotFoundException]
            {
                ;
            }
        }

        JmeterCSVResultsToJSON "$PSScriptRoot\$script:testDir\data.csv" "$PSScriptRoot\$script:testDir\data.json"

        It "should produce JSON file"  {
            "$PSScriptRoot\$script:testDir\data.json" | Should -Exist
        }
        It "should produce valid output in JSON file"  {
            $expected = Get-Content  -Path "$PSScriptRoot\$script:testDir\data_expected_output.json"
            $actual = Get-Content  -Path "$PSScriptRoot\$script:testDir\data.json"
            $actual = $actual.replace(' ', '')
            $expected = $expected.replace(' ', '')
            "$actual" | Should -Be "$expected"
        }

    }
    Context 'When I load properties' {
        It "should be loaded all properties with correct values" {
            $properties = LoadProperties "$PSScriptRoot\$script:testDir\workbooks.properties"
            $properties | Should -Not -BeNullOrEmpty
            $properties."workbooks.enabled" | Should -Be 1
            $properties."workbooks.workbooksID" | Should -Be testID
            $properties."workbooks.sharedkey" | Should -Be testKey
            $properties."workbooks.logType" | Should -Be testType
        }
    }
    Context 'When I send real data to Log Analytics' {
        It "should return HTTP OK" {
            $statusCode = SendRawDataToLogAnalytics -propertiesFilePath "$PSScriptRoot\$script:testDir\workbooks.e2e.properties" `
                                       -jsonFilePath "$PSScriptRoot\$script:testDir\data_expected_output.json"
            $statusCode | Should -Be 200
        }
    }


}

InModuleScope Workbooks{
    Describe "Workbook tests" {
        BeforeAll {
            Mock PostLogAnalyticsData
            Mock Get-Content { return "" }
            Mock LoadProperties { return "" }
        }
        BeforeEach {
            $statusCode = SendRawDataToLogAnalytics `
                                        -propertiesFilePath "$PSScriptRoot\test_data\workbooks.e2e.properties" `
                                        -jsonFilePath "$PSScriptRoot\test_data\data_expected_output.json"
        }
        Context 'When I run SendRawDataToLogAnalytics' {
            It "should run PostLogAnalyticsData once exactly" {
                Assert-VerifiableMock
                Assert-MockCalled PostLogAnalyticsData -Times 1
            }
            It "should run LoadProperties once exactly" {
                Assert-VerifiableMock
                $assertParams = @{
                    CommandName = 'LoadProperties'
                    Exactly = $true
                    Times = 1
                }
                Assert-MockCalled @assertParams
            }
        }
    }
}