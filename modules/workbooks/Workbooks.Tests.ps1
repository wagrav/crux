Import-Module $PSScriptRoot\Workbooks.psm1 -Force
$script:testDir = "$PSScriptRoot\test_data"

<#
    These are tests Module without mocks. We uset TestDrive not to leave side effects

 #>
Describe "Workbook Module tests without Mocks"  {
    BeforeAll {
        function GetFullPath {
            param(
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

        Convert-JmeterCSVResultsToJSON "$csv" "$json"

        It "should not throw exception"  {
            { Convert-JmeterCSVResultsToJSON "$TestDrive\idonotexists.csv" "$TestDrive\data.json" } | Should -Not -Throw
        }

    }

    Context -Name 'When I try to convert non-existing file'{
        BeforeAll { #sometimes $TestDrive is only available in Pester Blocks
            $csv = "$TestDrive\data_file.csv"
            $csvWithNewHeader = "$TestDrive\out_data_file.json"
            Add-ColumnToCSV "$csv" "$csvWithNewHeader" 'newHeader' 'newValue'
        }

        It "should not throw exception"  {
            $expected = Get-Content  -Path "$csvWithNewHeader"
            $expected | Should -Be @('"header1","header2","header3","newHeader"', '"1","2","3","newValue"', '"1","2","3","newValue"', '"1","2","3","newValue"')
        }

    }
    #perhaps we can remove that after migrating to TestDrive
    Context 'When I convert JMETER CSV results' {
        BeforeAll {
            Convert-JmeterCSVResultsToJSON "$TestDrive\data.csv" "$TestDrive\data.json"
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
            $properties = Read-Properties "$TestDrive\workbooks.properties"
            $properties | Should -Not -BeNullOrEmpty
            $properties."workbooks.workbooksID" | Should -Be testID
            $properties."workbooks.sharedkey" | Should -Be testKey
            $properties."workbooks.logType" | Should -Be testType
        }
    }
    Context 'When I send real data to Log Analytics' {
        It "should return HTTP OK" {
            $statusCode = Send-RawDataToLogAnalytics -PropertiesFilePath "$TestDrive\workbooks.e2e.properties" `
                                       -FilePathJSON "$TestDrive\data_expected_output.json"
            $statusCode | Should -Be 200
        }
    }


}
<#
    These are modules tests so we use specific scope

#>
InModuleScope Workbooks{
    Describe "Send-RawDataToLogAnalytics tests" {
        BeforeAll {
            Mock Send-LogAnalyticsData
            Mock Get-Content { return "" }
            Mock Read-Properties { return "" }
            Copy-Item "$testDir\data_expected*" -Destination "$TestDrive"
            Copy-Item "$testDir\*.properties" -Destination "$TestDrive"
        }
        BeforeEach {
            Send-RawDataToLogAnalytics `
                                -PropertiesFilePath "$TestDrive\workbooks.e2e.properties" `
                                -FilePathJSON "$TestDrive\data_expected_output.json"
        }
        Context 'When I run Send-RawDataToLogAnalytics' {
            It "should run Send-LogAnalyticsData once exactly" {
                Assert-VerifiableMock
                Assert-MockCalled Send-LogAnalyticsData -Times 1
            }
            It "should run Read-Properties once exactly" {
                Assert-VerifiableMock
                $assertparams = @{
                    CommandName = 'Read-Properties'
                    Exactly = $true
                    Times = 1
                }
                Assert-MockCalled @assertparams
            }
        }
    }
    Describe "Send-DataToLogAnalytics tests" {
        BeforeAll {
            Mock Convert-JmeterCSVResultsToJSON
            Mock Send-RawDataToLogAnalytics
            Mock Read-Properties
        }
        BeforeEach {
            Send-DataToLogAnalytics
        }
        Context 'When I run Send-DataToLogAnalytics' {
            It "should run all functions" {
                Should -InvokeVerifiable
            }
            It "should run Convert-JmeterCSVResultsToJSON once exactly" {
                Should -Invoke Convert-JmeterCSVResultsToJSON -Times 1 -Exactly
            }
            It "should run Send-RawDataToLogAnalytics once exactly" {
                Should -Invoke Send-RawDataToLogAnalytics -Times 1 -Exactly
            }
        }
    }

    Describe "Send-DataToLogAnalytics tests" {
        BeforeAll {
            Mock Convert-JmeterCSVResultsToJSON { throw [System.IO.FileNotFoundException] "Dummy Exception"  }
            Mock Send-RawDataToLogAnalytics
            Mock Read-Properties
            Mock Write-Host
        }
        Context 'When I run Send-DataToLogAnalytics and error is thrown by Convert-JmeterCSVResultsToJSON' {
            It "should return status 999" {
                $status =  Send-DataToLogAnalytics
                $status |  Should -Be 999
            }
            It "should not throw exception" {
                { Send-DataToLogAnalytics } | Should -Not -Throw
            }
        }
    }
}

<#
    These are script tests, we mock only functions in script
#>
Describe 'Workbooks script tests' {
    BeforeAll {
        . $PSScriptRoot\Workbooks.ps1 -Force
    }
    Context 'When script is run and data is uploaded' {
        BeforeAll {
            Mock Send-JMeterDataToLogAnalytics { return "200" }
        }
        It 'Should run Send-JMeterDataToLogAnalytics function once exactly' {
            Start-Script
            Should -Invoke Send-JMeterDataToLogAnalytics -Times 1 -Exactly
        }
    }
    Context 'When Send-JMeterDataToLogAnalytics is run and data is uploaded'{
        BeforeAll {
            Mock Send-DataToLogAnalytics { return "200" }
        }
        It 'Should run Send-DataToLogAnalytics function once exactly' {
            Start-Script
            Should -Invoke Send-DataToLogAnalytics -Times 1 -Exactly
        }
    }
    Context 'When Send-DataToLogAnalytics fails to upload data' {
        BeforeAll {
            Mock Send-DataToLogAnalytics { return "503" }
        }
        It 'Should exit with error' {
            { Start-Script } | Should -Throw

        }
    }
    Context 'When script is run in dry-run' {
        BeforeAll {
            . $PSScriptRoot\Workbooks.ps1 -DryRun $true -Force
            Mock Send-JMeterDataToLogAnalytics { return "200" }
            Mock Add-MetaDataToCSV
        }
        It 'Should not execute Send-DataToLogAnalytics' {
            Start-Script
            Should -Invoke Send-JMeterDataToLogAnalytics -Times 0 -Exactly

        }
        It 'Should  execute Add-MetaDataToCSV' {
            Start-Script
            Should -Invoke Add-MetaDataToCSV -Times 1 -Exactly

        }
    }
    Context 'When CSV size is exceeded' {

        BeforeAll {
            Set-Variable AZURE_POST_LIMIT_EXCEEDED -option Constant -value 40000000
            . $PSScriptRoot\Workbooks.ps1 -DryRun $true -Force
            Mock `
                -CommandName Get-Item `
                -MockWith { [PSCustomObject]@{ length = "$AZURE_POST_LIMIT_EXCEEDED" } }
            Mock Add-MetaDataToCSV
        }
        It 'Should throw file size exceeded error' {
            { Start-Script } | Should -Throw "File size exceeds limit of 30 Megs:*"
        }
    }
    Context -Name 'When I add multiple columns to CSV file'{
        BeforeAll { #sometimes $TestDrive is only available in Pester Blocks
            . $PSScriptRoot\Workbooks.ps1 -DryRun $true -JmeterArg 'args' -BuildId 'id' -PipelineId 'pid' -BuildStatus 'status' -Force
            Copy-Item "$testDir\data*" -Destination "$TestDrive"
            $csv = "$TestDrive\data_file.csv"
            $csvWithNewColumns = "$TestDrive\out_data_file.json"
            Add-MetaDataToCSV -FilePathCSV "$csv" -OutFilePathCSV "$csvWithNewColumns"
        }

        It "should all columns appear in new file"  {
            $expected = Get-Content  -Path "$csvWithNewColumns"
            $expected | Should -Be @('"header1","header2","header3","jmeterArgs","buildId","buildStatus","pipelineId"', '"1","2","3","args","id","status","pid"', '"1","2","3","args","id","status","pid"', '"1","2","3","args","id","status","pid"')
        }

    }
}
