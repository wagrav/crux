Import-Module $PSScriptRoot\Workbooks.psm1 -Force
$script:testDir = "$PSScriptRoot\test_data"

<#
    These are tests Module without mocks. We uset TestDrive not to leave side effects

 #>
Describe "Workbook Module tests without Mocks"  {
    BeforeAll {
        Function GetFullPath {
            Param(
                [string] $Path
            )
            return $Path.Replace('TestDrive:', (Get-PSDrive TestDrive).Root)
        }
        Write-Host "Running with powershell version" $PSVersionTable.PSVersion
        Copy-Item "$testDir\data*" -Destination "$TestDrive"
        Copy-Item "$testDir\*.properties" -Destination "$TestDrive"
        Write-Host "Test Data copied to TestDrive:\ at: $(GetFullPath -Path 'TestDrive:\')"
        Write-Host "TestDrive contents: $(Get-ChildItem -Path $TestDrive)"

    }


    Context -Name 'When I try to convert non-existing file'{
        $csv = "$TestDrive\data.csv"
        $json = "$TestDrive\data.json"

        JmeterCSVResultsToJSON "$csv" "$json"

        It "should not throw exception"  {
            { JmeterCSVResultsToJSON "$TestDrive\idonotexists.csv" "$TestDrive\data.json" } | Should -Not -Throw
        }

    }

    Context -Name 'When I try to convert non-existing file'{
        BeforeAll { #sometimes $TestDrive is only available in Pester Blocks
            $csv = "$TestDrive\data_file.csv"
            $csvWithNewHeader = "$TestDrive\out_data_file.json"
            AddColumnToCSV "$csv" "$csvWithNewHeader" 'newHeader' 'newValue'
        }

        It "should not throw exception"  {
            $expected = Get-Content  -Path "$csvWithNewHeader"
            $expected | Should -Be @('"header1","header2","header3","newHeader"', '"1","2","3","newValue"', '"1","2","3","newValue"', '"1","2","3","newValue"')
        }

    }
    #perhaps we can remove that after migrating to TestDrive
    Context 'When I convert JMETER CSV results' {
        BeforeAll {
            JmeterCSVResultsToJSON "$TestDrive\data.csv" "$TestDrive\data.json"
        }
        It "should produce JSON file"  {
            "$TestDrive\data.json" | Should -Exist
        }
        It "should produce valid output in JSON file"  {
            $expected = Get-Content  -Path "$TestDrive\data_expected_output.json"
            $actual = Get-Content  -Path "$TestDrive\data.json"
            $actual = $actual.replace(' ', '')
            $expected = $expected.replace(' ', '')
            "$actual" | Should -Be "$expected"
        }

    }
    Context 'When I load properties' {
        It "should be loaded all properties with correct values" {
            $properties = LoadProperties "$TestDrive\workbooks.properties"
            $properties | Should -Not -BeNullOrEmpty
            $properties."workbooks.workbooksID" | Should -Be testID
            $properties."workbooks.sharedkey" | Should -Be testKey
            $properties."workbooks.logType" | Should -Be testType
        }
    }
    Context 'When I send real data to Log Analytics' {
        It "should return HTTP OK" {
            $statusCode = SendRawDataToLogAnalytics -propertiesFilePath "$TestDrive\workbooks.e2e.properties" `
                                       -filePathJSON "$TestDrive\data_expected_output.json"
            $statusCode | Should -Be 200
        }
    }


}
<#
    These are modules tests so we use specific scope

#>
InModuleScope Workbooks{
    Describe "SendRawDataToLogAnalytics tests" {
        BeforeAll {
            Mock PostLogAnalyticsData
            Mock Get-Content { return "" }
            Mock LoadProperties { return "" }
            Copy-Item "$testDir\data_expected*" -Destination "$TestDrive"
            Copy-Item "$testDir\*.properties" -Destination "$TestDrive"
        }
        BeforeEach {
            SendRawDataToLogAnalytics `
                                -propertiesFilePath "$TestDrive\workbooks.e2e.properties" `
                                -filePathJSON "$TestDrive\data_expected_output.json"
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
    Describe "SendDataToLogAnalytics tests" {
        BeforeAll {
            Mock JmeterCSVResultsToJSON
            Mock SendRawDataToLogAnalytics
            Mock LoadProperties
        }
        BeforeEach {
            SendDataToLogAnalytics
        }
        Context 'When I run SendDataToLogAnalytics' {
            It "should run all functions" {
                Should -InvokeVerifiable
            }
            It "should run JmeterCSVResultsToJSON once exactly" {
                Should -Invoke JmeterCSVResultsToJSON -Times 1 -Exactly
            }
            It "should run SendRawDataToLogAnalytics once exactly" {
                Should -Invoke SendRawDataToLogAnalytics -Times 1 -Exactly
            }
        }
    }

    Describe "SendDataToLogAnalytics tests" {
        BeforeAll {
            Mock JmeterCSVResultsToJSON { throw [System.IO.FileNotFoundException] "Dummy Exception"  }
            Mock SendRawDataToLogAnalytics
            Mock LoadProperties
            Mock Write-Host
        }
        Context 'When I run SendDataToLogAnalytics and error is thrown by JmeterCSVResultsToJSON' {
            It "should return status 999" {
                $status =  SendDataToLogAnalytics
                $status |  Should -Be 999
            }
            It "should not throw exception" {
                { SendDataToLogAnalytics } | Should -Not -Throw
            }
        }
    }
}

<#
    These are script tests, we mock only functions in script
#>
Describe 'Workbooks script tests' {
    BeforeAll {
        . $PSScriptRoot\Workbooks.ps1
    }
    Context 'When script is run and data is uploaded' {
        BeforeAll {
            Mock sendJMeterDataToLogAnalytics { return "200" }
        }
        It 'Should run sendJMeterDataToLogAnalytics function once exactly' {
            run
            Should -Invoke sendJMeterDataToLogAnalytics -Times 1 -Exactly
        }
    }
    Context 'When sendJMeterDataToLogAnalytics is run and data is uploaded'{
        BeforeAll {
            Mock SendDataToLogAnalytics { return "200" }
        }
        It 'Should run SendDataToLogAnalytics function once exactly' {
            run
            Should -Invoke SendDataToLogAnalytics -Times 1 -Exactly
        }
    }
    Context 'When SendDataToLogAnalytics fails to upload data' {
        BeforeAll {
            Mock SendDataToLogAnalytics { return "503" }
        }
        It 'Should exit with error' {
            { run } | Should -Throw

        }
    }
    Context 'When script is run in dry-run' {
        BeforeAll {
            . $PSScriptRoot\Workbooks.ps1 -dryRun $true -Force
            Mock sendJMeterDataToLogAnalytics { return "200" }
            Mock addMetaDataToCSV
        }
        It 'Should not execute SendDataToLogAnalytics' {
            run
            Should -Invoke sendJMeterDataToLogAnalytics -Times 0 -Exactly

        }
        It 'Should  execute addMetaDataToCSV' {
            run
            Should -Invoke addMetaDataToCSV -Times 1 -Exactly

        }
    }
    Context 'When CSV size is exceeded' {

        BeforeAll {
            Set-Variable AZURE_POST_LIMIT_EXCEEDED -option Constant -value 40000000
            . $PSScriptRoot\Workbooks.ps1 -dryRun $true -Force
            Mock `
                -CommandName Get-Item `
                -MockWith { [PSCustomObject]@{ length = "$AZURE_POST_LIMIT_EXCEEDED" } }
            Mock addMetaDataToCSV
        }
        It 'Should throw file size exceeded error' {
            { run } | Should -Throw "File size exceeds limit of 30 Megs:*"
        }
    }
}
