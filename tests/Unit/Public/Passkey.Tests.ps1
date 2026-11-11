BeforeDiscovery {
    $RootItem = Get-Item $PSScriptRoot
    while ($RootItem.GetDirectories().Name -notcontains 'source')
    {
        $RootItem = $RootItem.Parent
    }
    $ProjectPath = $RootItem.FullName
    $ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
            $_.Directory.Name -eq 'source' -and (Test-ModuleManifest $_.FullName -ErrorAction Stop)
        }).BaseName
    Import-Module $ProjectName -Force
}

InModuleScope $ProjectName {
    Describe 'Get-IMPasskey' -Tag 'Unit', 'Get-IMPasskey' {
        BeforeAll {
            $Id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            $OtherId = 'cde7ceba-f301-4e9e-87a2-163937a2a3db'
            Mock InvokeImmichRestMethod {
                [pscustomobject]@{ id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'; name = $null; usedAt = $null }
            }
        }
        It 'Lists passkeys and preserves nullable response fields' {
            $Result = Get-IMPasskey
            $Result.id | Should -Be $Id
            $Result.name | Should -BeNullOrEmpty
            $Result.usedAt | Should -BeNullOrEmpty
            Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Get' -and $RelativePath -eq '/passkeys' -and $null -eq $QueryParameters
            }
        }
        It 'Retrieves each specified passkey by ID' {
            Get-IMPasskey -Id $Id, $OtherId
            Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Get' -and $RelativePath -eq "/passkeys/$Id"
            }
            Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Get' -and $RelativePath -eq "/passkeys/$OtherId"
            }
        }
        It 'Accepts IDs from pipeline values and object properties' {
            $Id | Get-IMPasskey
            [pscustomobject]@{ Id = $OtherId } | Get-IMPasskey
            Should -Invoke InvokeImmichRestMethod -Times 2 -Exactly
        }
        It 'Forwards an explicit session' {
            $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
            Get-IMPasskey -Session $Session
            Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                $ImmichSession -eq $Session
            }
        }
        It 'Rejects invalid IDs' {
            { Get-IMPasskey -Id 'invalid' } | Should -Throw
            Should -Invoke InvokeImmichRestMethod -Times 0
        }
        It 'Propagates API errors' {
            Mock InvokeImmichRestMethod { throw 'Passkey request failed' }
            { Get-IMPasskey } | Should -Throw '*Passkey request failed*'
        }
    }

    Describe 'Rename-IMPasskey' -Tag 'Unit', 'Rename-IMPasskey' {
        BeforeAll {
            $Id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            Mock InvokeImmichRestMethod { [pscustomobject]@{ id = $Id; name = $Body.name; usedAt = $null } }
        }
        It 'Sends the new name and returns the response' {
            $Result = Rename-IMPasskey -Id $Id -Name 'Security key' -Confirm:$false
            $Result.name | Should -Be 'Security key'
            $Result.usedAt | Should -BeNullOrEmpty
            Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Patch' -and $RelativePath -eq "/passkeys/$Id" -and
                $Body.Count -eq 1 -and $Body.name -eq 'Security key'
            }
        }
        It 'Sends explicit null when clearing the name' {
            Rename-IMPasskey -Id $Id -ClearName -Confirm:$false
            Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                $Body.ContainsKey('name') -and $null -eq $Body.name
            }
        }
        It 'Accepts pipeline objects and forwards an explicit session' {
            $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
            [pscustomobject]@{ id = $Id } | Rename-IMPasskey -Name 'Key' -Session $Session -Confirm:$false
            Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                $ImmichSession -eq $Session -and $RelativePath -eq "/passkeys/$Id"
            }
        }
        It 'Does not issue requests for WhatIf' {
            Rename-IMPasskey -Id $Id -Name 'Key' -WhatIf
            Should -Invoke InvokeImmichRestMethod -Times 0
        }
        It 'Rejects invalid inputs and a false ClearName switch' {
            { Rename-IMPasskey -Id 'invalid' -Name 'Key' } | Should -Throw
            { Rename-IMPasskey -Id $Id -Name '' } | Should -Throw
            { Rename-IMPasskey -Id $Id -ClearName:$false } | Should -Throw
            Should -Invoke InvokeImmichRestMethod -Times 0
        }
    }

    Describe 'Remove-IMPasskey' -Tag 'Unit', 'Remove-IMPasskey' {
        BeforeAll {
            $Id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            $OtherId = 'cde7ceba-f301-4e9e-87a2-163937a2a3db'
            Mock InvokeImmichRestMethod {}
        }
        It 'Deletes every specified passkey' {
            Remove-IMPasskey -Id $Id, $OtherId -Confirm:$false
            Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Delete' -and $RelativePath -eq "/passkeys/$Id"
            }
            Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Delete' -and $RelativePath -eq "/passkeys/$OtherId"
            }
        }
        It 'Accepts pipeline objects and forwards an explicit session' {
            $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
            [pscustomobject]@{ id = $Id } | Remove-IMPasskey -Session $Session -Confirm:$false
            Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                $ImmichSession -eq $Session -and $RelativePath -eq "/passkeys/$Id"
            }
        }
        It 'Does not issue requests for WhatIf' {
            Remove-IMPasskey -Id $Id -WhatIf
            Should -Invoke InvokeImmichRestMethod -Times 0
        }
        It 'Rejects an invalid ID' {
            { Remove-IMPasskey -Id 'invalid' -Confirm:$false } | Should -Throw
            Should -Invoke InvokeImmichRestMethod -Times 0
        }
    }
}
