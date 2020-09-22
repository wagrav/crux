Import-Module $PSScriptRoot\Azure.psm1 -Force


Describe "PostLogAnalyticsData tests" {

    Context 'When I run PostLogAnalyticsData' {
        BeforeEach {
            Mock BuildSignature { "" }
            Mock Invoke-WebRequest { "" }
            $fakeKey = '2tROkttxLKAPZA/7WkEx4P+0GOhZ7BkWzIp0OublY/h6I8x4/iffffffWFx7YAT6bAHR4OKpt8ujAN7a1cL7lg=='
            PostLogAnalyticsData -customerId foo `
                            -sharedKey $fakeKey `
                            -body foo `
                            -logType foo
        }
        It "should run BuildSignature once exactly" {
            Should -Invoke BuildSignature -Times 1 -Exactly
        }

        It "should run Invoke-WebRequest once exactly" {
            Should -Invoke Invoke-WebRequest -Times 1 -Exactly
        }
    }
}


