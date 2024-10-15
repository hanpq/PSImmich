BeforeDiscovery {
    $RootItem = Get-Item $PSScriptRoot
    while ($RootItem.GetDirectories().Name -notcontains 'source')
    {
        $RootItem = $RootItem.Parent
    }
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
                })
        }
    ).BaseName

    Import-Module $ProjectName -Force
}

InModuleScope $ProjectName {

    Describe 'AddCustomType' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'ConvertFromSecureString' -Tag 'Unit' {
        Context 'When providing a securestring' {
            It 'Should return the correct string' {
                $SecureString = ConvertTo-SecureString -String 'immich' -AsPlainText -Force
                ConvertFromSecureString -SecureString $SecureString | Should -BeExactly 'immich'
            }
        }
    }
    Describe 'InvokeImmichRestMethod' -Tag 'Unit' {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -Verifiable -MockWith {

            }
            Mock -CommandName 'ValidateToken' -Verifiable -MockWith {

            }
            $Session = [ImmichSession]::New('https://test.domain.com/api', (ConvertTo-SecureString -String 'string' -AsPlainText -Force))
        }
        Context 'When calling get without query or body' {
            It 'Should not throw' {
                { InvokeImmichRestMethod -Method get -RelativePath '/auth/login' -immichsession:$session }
            }
        }
        Context 'When calling get with query' {
            It 'Should not throw' {
                { InvokeImmichRestMethod -Method get -immichsession:$session -RelativePath '/auth/login' -QueryParameters:@{
                        param1 = 'string'
                        param2 = Get-Date
                        param3 = 1
                    } } | Should -Not -Throw
            }
        }
        Context 'When calling post with body' {
            It 'Should not throw' {
                { InvokeImmichRestMethod -Method post -immichsession:$session -RelativePath '/auth/login' -Body:@{
                        param1 = 'string'
                        param2 = Get-Date
                        param3 = 1
                    } } | Should -Not -Throw
            }
        }
    }
    Describe 'SelectBinding' -Tag 'Unit' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'ValidateToken' -Tag 'Unit' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
}
