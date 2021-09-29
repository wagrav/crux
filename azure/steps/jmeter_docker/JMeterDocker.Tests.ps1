BeforeAll {
    Import-Module $PSScriptRoot/JMeterDocker.psm1 -Force
    . $PSScriptRoot/JMeterDocker.ps1 -Force -SkipRun $TRUE #import w/o execution
}
Describe "Script Tests" {
    Context "When Start-JMeterTests is run" {
            BeforeAll {
                #all of these should be executed
                Mock -CommandName Split-Path { } -Verifiable
                Mock -CommandName Write-Host { } -Verifiable
                Mock -CommandName Copy-Item { } -Verifiable
                Mock Stop-JMeterContainer { } -Verifiable
                Mock Start-JMeterContainer -Verifiable
                Mock Start-JmeterTest -Verifiable
                Mock Start-SimpleTableServer -Verifiable
                Mock Show-TestDirectory -Verifiable
                Mock Set-Permissions -Verifiable
                Mock Copy-Artifacts -Verifiable
                #default variables are loaded up
                Start-JMeterTests  `
                  -Image $Image `
                  -ContainerName $ContainerName `
                  -JMXPathOnAgent $JMXPathOnAgent `
                  -TestDataDirOnAgent $TestDataDirOnAgent `
                  -ContainerTestDataDir $ContainerTestDataDir `
                  -UserArgs $UserArgs `
                  -FixedArgs $FixedArgs `
                  -SleepSeconds $SleepSeconds `
                  -ArtifactsDirectory $ArtifactsDirectory `
                  -SkipRun $FALSE `
                  -JVM_ARGS "$JVM_ARGS"
            }
            It "should execute Write-Host with Running message"  -Tag debug {
                Assert-MockCalled Write-Host -Scope Context -ParameterFilter { $Object -eq "Running" }
            }
            It "should verifiable mocks be called"  -Tag debug {
                Should -InvokeVerifiable
            }
            It "should Stop-JMeterContainer be called twice exactly"  -Tag debug {
                Should -Invoke Stop-JMeterContainer -Scope Context -Times 2
            }
            It "should all script variables have default values"  -Tag debug {
                $variables =@(
                                $Image,
                                $ContainerName,
                                $JMXPathOnAgent,
                                $TestDataDirOnAgent,
                                $ContainerTestDataDir,
                                $UserArgs,
                                $FixedArgs,
                                $SleepSeconds,
                                $ArtifactsDirectory,
                                $SkipRun,
                                $JVM_ARGS)
                foreach($variable in $variables){
                    $variable | Should -Not -BeNullOrEmpty
                }
            }

    }
    Context "When Start-JMeterTests is run with SkipRun" {
        BeforeAll {
            Mock -CommandName Write-Host { }
            Start-JMeterTests  `
                  -Image $Image `
                  -ContainerName $ContainerName `
                  -JMXPathOnAgent $JMXPathOnAgent `
                  -TestDataDirOnAgent $TestDataDirOnAgent `
                  -ContainerTestDataDir $ContainerTestDataDir `
                  -UserArgs $UserArgs `
                  -FixedArgs $FixedArgs `
                  -SleepSeconds $SleepSeconds `
                  -ArtifactsDirectory $ArtifactsDirectory `
                  -SkipRun $TRUE
        }
        It "should  execute Write-Host with Skipped message"   -Tag debug{
           Assert-MockCalled Write-Host -Scope Context -ParameterFilter { $Object -eq "Skipped" }
        }
    }
    Context "When Start-JMeterTests is run without mocks" -Tag E2E   {

        BeforeAll {
            function GetFullPath {
                param(
                    [string] $Path
                )
                return $Path.Replace('TestDrive:', (Get-PSDrive TestDrive).Root)
            }

            $TestDataDirOnAgent = "$PSScriptRoot/test_data"
            $ArtifactsDirectory = "$(GetFullPath $TestDrive)"
            $JMXPathOnAgent = "$PSScriptRoot/test_jmx/test_table_server.jmx"
            $ContainerTestDataDir='/test'
            $FixedArgs= "-o $ContainerTestDataDir/report/ -f -l $ContainerTestDataDir/results.csv -e -Gsts=localhost -Gchromedriver=/usr/bin/chromedriver"
            Write-Host "Results will be stored in $(GetFullPath $TestDrive)"
            Start-JMeterTests `
                  -Image $Image `
                  -ContainerName $ContainerName `
                  -JMXPathOnAgent $JMXPathOnAgent `
                  -TestDataDirOnAgent $TestDataDirOnAgent `
                  -ContainerTestDataDir $ContainerTestDataDir `
                  -UserArgs $UserArgs `
                  -FixedArgs $FixedArgs `
                  -SleepSeconds $SleepSeconds `
                  -ArtifactsDirectory $ArtifactsDirectory `
                  -SkipRun $FALSE
        }
        It "test file artifacts should be created"  {

            $artifacts=@('report','jmeter.log','errors.xml','results.csv')
            foreach($artifact in $artifacts)
            {
                "$ArtifactsDirectory/$artifact"| Should -Exist
            }
        }
        It "jmeter.log and results.csv should not be empty"  {
            $artifacts=@('jmeter.log','results.csv')
            foreach($artifact in $artifacts)
            {
                Get-Content -Path "$ArtifactsDirectory/$artifact"| Should -Not -BeNullOrEmpty
            }
        }
        It "no errors should be logged to errors.xml"  {
            Get-Content -Path "$ArtifactsDirectory/errors.xml"| Should -BeNullOrEmpty
        }
    }
}
Import-Module $PSScriptRoot/JMeterDocker.psm1 -Force
InModuleScope JMeterDocker {
    Describe "Module Tests" -Tag ModuleTests {
        It "should Copy-Artifacts execute Copy-Item 4 times exactly"  {
            Mock -CommandName docker { }
            Copy-Artifacts
            Assert-MockCalled docker -Scope It -Times 4 -Exactly
        }
        It "should Start-JmeterTest execute correct jmeter command with proper args"  {
            Mock Start-CommandInsideDocker {
                Write-Host $Command
                return $Command
            }
            Start-JmeterTest -ContainerName crux `
                            -JMXPath /test/test.jmx `
                            -UserArgs 'userargs' `
                            -FixedArgs 'fixedargs' `
                | Should -Be 'sh /jmeter/apache-jmeter-*/bin/jmeter.sh -n -t /test/test.jmx userargs fixedargs'

        }

    }
}