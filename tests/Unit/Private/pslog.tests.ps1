BeforeDiscovery {
        $RootItem = Get-Item $PSScriptRoot
    while ($RootItem.GetDirectories().Name -notcontains "source") {$RootItem = $RootItem.Parent}
    $ProjectPath = $RootItem.FullName
    $ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -eq 'source') -and
            $(try
                {
                    Test-ModuleManifest $_.FullName -ErrorAction Stop
                }
                catch
                {
                    $false
                }) }
    ).BaseName

    Import-Module $ProjectName -Force
}

InModuleScope $ProjectName {
    Describe pslog {
        BeforeAll {
            Mock -CommandName Get-Date -MockWith { [datetime]'2000-01-01 01:00:00+00:00' }
            $CompareString = ([datetime]'2000-01-01 01:00:00+00:00').ToString('yyyy-MM-ddThh:mm:ss.ffffzzz')
        }
        Context 'Success' {
            It 'Log file should have content' {
                pslog -Severity Success -Message 'Message' -LogDirectoryOverride 'TestDrive:\Logs' -DoNotLogToConsole
                Get-Content 'TestDrive:\Logs\2000-01-01.log' | Should -BeExactly "$CompareString`tSuccess`tdefault`tMessage"
            }
        }
        Context 'Info' {
            It 'Log file should have content' {
                pslog -Severity Info -Message 'Message' -LogDirectoryOverride 'TestDrive:\Logs' -DoNotLogToConsole
                Get-Content 'TestDrive:\Logs\2000-01-01.log' | Should -BeExactly "$CompareString`tInfo`tdefault`tMessage"
            }
        }
        Context 'Warning' {
            It 'Log file should have content' {
                pslog -Severity Warning -Message 'Message' -LogDirectoryOverride 'TestDrive:\Logs' -DoNotLogToConsole
                Get-Content 'TestDrive:\Logs\2000-01-01.log' | Should -BeExactly "$CompareString`tWarning`tdefault`tMessage"
            }
        }
        Context 'Error' {
            It 'Log file should have content' {
                pslog -Severity Error -Message 'Message' -LogDirectoryOverride 'TestDrive:\Logs' -DoNotLogToConsole
                Get-Content 'TestDrive:\Logs\2000-01-01.log' | Should -BeExactly "$CompareString`tError`tdefault`tMessage"
            }
        }
        Context 'Verbose' {
            It 'Log file should have content' {
                pslog -Severity Verbose -Message 'Message' -LogDirectoryOverride 'TestDrive:\Logs' -DoNotLogToConsole -Verbose:$true
                Get-Content 'TestDrive:\Logs\2000-01-01.log' | Should -BeExactly "$CompareString`tVerbose`tdefault`tMessage"
            }
        }
        Context 'Debug' {
            It 'Log file should have content' {
                pslog -Severity Debug -Message 'Message' -LogDirectoryOverride 'TestDrive:\Logs' -DoNotLogToConsole -Debug:$true
                Get-Content 'TestDrive:\Logs\2000-01-01.log' | Should -BeExactly "$CompareString`tDebug`tdefault`tMessage"
            }
        }
    }
}
