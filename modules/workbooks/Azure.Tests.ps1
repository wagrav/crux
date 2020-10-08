Import-Module $PSScriptRoot\Azure.psm1 -Force


Describe "Post-LogAnalyticsData tests" {

    Context 'When I run PostLogAnalyticsData' {
        BeforeEach {
            Mock New-Signature { "" }
            Mock Invoke-WebRequest { "" }
            $fakeKey = '2tROkttxLKAPZA/7WkEx4P+0GOhZ7BkWzIp0OublY/h6I8x4/iffffffWFx7YAT6bAHR4OKpt8ujAN7a1cL7lg=='
            Send-LogAnalyticsData -customerId foo `
                            -SharedKey $fakeKey `
                            -Body foo `
                            -logType foo
        }
        It "should run Build-Signature once exactly" {
            Should -Invoke New-Signature -Times 1 -Exactly
        }

        It "should run Invoke-WebRequest once exactly" {
            Should -Invoke Invoke-WebRequest -Times 1 -Exactly
        }
    }
}


