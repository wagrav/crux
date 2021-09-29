param(
    $Image = "gabrielstar/crux-master:0.0.1",
    $ContainerName = "crux",
    $JMXPathOnAgent = "${PSScriptRoot}/test_jmx/test_table_server.jmx",
    $TestDataDirOnAgent = "${PSScriptRoot}/test_data",
    $ContainerTestDataDir = "/test",
    $UserArgs = "-Jthreads=10 -Jloops=10",
    $FixedArgs = "-o $ContainerTestDataDir/report/ -f -l $ContainerTestDataDir/results.csv -e -Jsts=localhost -Jchromedriver=/usr/bin/chromedriver",
    $SleepSeconds = 2,
    $ArtifactsDirectory = "$PSScriptRoot/../../../kubernetes/tmp",
    [Boolean]$SkipRun = $FALSE,
    $JVM_ARGS = "-Xms512M -Xmx1G"
)
Import-Module $PSScriptRoot\JMeterDocker.psm1 -Force

function Start-JMeterTests($Image, $ContainerName, $JMXPathOnAgent, $TestDataDirOnAgent, $ContainerTestDataDir, $UserArgs, $FixedArgs, $SleepSeconds, $ArtifactsDirectory, $SkipRun, $JVM_ARGS)
{
    if(!$SkipRun)
    {
        Write-Host "Running"
        $testName = Split-Path $JMXPathOnAgent -leaf
        Copy-Item $JMXPathOnAgent $TestDataDirOnAgent
        Stop-JMeterContainer -ContainerName $ContainerName
        Start-JMeterContainer -Image $Image -ContainerName $ContainerName -TestDataDir $TestDataDirOnAgent -ContainerTestDataDir $ContainerTestDataDir -JVM_ARGS "$JVM_ARGS"
        Start-SimpleTableServer -ContainerName $ContainerName -DataSetDirectory $ContainerTestDataDir -SleepSeconds $SleepSeconds
        Show-TestDirectory -ContainerName $ContainerName -Directory $ContainerTestDataDir
        Start-JmeterTest -ContainerName $ContainerName -JMXPath $ContainerTestDataDir/$testName -UserArgs $UserArgs -FixedArgs $FixedArgs -ContainerTestDataDir $ContainerTestDataDir
        Set-Permissions -ContainerName $ContainerName -Directory $ContainerTestDataDir -Permissions "777" #default owner artifacts created is root hence allow all
        Show-TestDirectory -ContainerName $ContainerName -Directory $ContainerTestDataDir
        Copy-Artifacts -ContainerName $ContainerName -ContainerTestDataDir $ContainerTestDataDir -ArtifactsDirectory $ArtifactsDirectory -TestDataDirOnAgent $TestDataDirOnAgent
        Stop-JMeterContainer -ContainerName $ContainerName
    }else{
        Write-Host "Skipped"
    }
}
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
                  -SkipRun $SkipRun `
                  -JVM_ARGS "$JVM_ARGS"

