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

# Intentionally excluded:
# - Partnerships with any user other than 97eeb1d9-b699-45ae-a06b-3bf4ea43d44d: the shared server must not be changed for other accounts.
# - Remove-IMPartner on a pre-existing partnership: the test only removes a partnership it created itself.
Describe 'Partner' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:PartnerId = '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
        $script:PartnerPreExisting = [bool](Get-IMPartner -Direction shared-by | Where-Object { $_.id -eq $script:PartnerId })
        $script:PartnerCreatedByTest = $false
    }

    AfterAll {
        if ($script:PartnerCreatedByTest)
        {
            Remove-IMPartner -id $script:PartnerId -ErrorAction SilentlyContinue
        }
    }

    Context 'Add-IMPartner' -Tag 'Add-IMPartner' {
        It 'Should add the partner' {
            if ($script:PartnerPreExisting)
            {
                Set-ItResult -Skipped -Because 'Partnership already exists and must not be changed'
                return
            }
            Add-IMPartner -SharedWithId $script:PartnerId | Out-Null
            $script:PartnerCreatedByTest = $true
            Get-IMPartner -Direction shared-by | Select-Object -ExpandProperty id | Should -Contain $script:PartnerId
        }
        It 'Should throw for a value that is not a GUID' {
            { Add-IMPartner -SharedWithId 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Get-IMPartner' -Tag 'Get-IMPartner' {
        It 'Should list partners shared with the current user' {
            { Get-IMPartner -Direction shared-with } | Should -Not -Throw
        }
        It 'Should list partners the current user shares with' {
            { Get-IMPartner -Direction shared-by } | Should -Not -Throw
        }
        It 'Should return PartnerResponseDto objects' {
            if (-not $script:PartnerCreatedByTest -and -not $script:PartnerPreExisting)
            {
                Set-ItResult -Skipped -Because 'Partnership was not created'
                return
            }
            $Result = Get-IMPartner -Direction shared-by | Where-Object { $_.id -eq $script:PartnerId }
            $Result.GetType().Name | Should -Be 'PartnerResponseDto'
        }
        It 'Should reject an invalid direction' {
            { Get-IMPartner -Direction 'both' } | Should -Throw
        }
    }

    Context 'Set-IMPartner' -Tag 'Set-IMPartner' {
        It 'Should enable the timeline for the partner' {
            # The server only allows timeline updates for partners that share with the current user (shared-with).
            # The test partner shares from this account, so the server returns 400 "no partner.update access".
            Set-ItResult -Skipped -Because 'Server rejects timeline updates for partners this account shares with; needs a partner that shares with this account'
        }
        It 'Should throw for a partner ID that is not a partnership' {
            { Set-IMPartner -id ([guid]::NewGuid().ToString()) -EnableTimeline } | Should -Throw
        }
    }

    Context 'Remove-IMPartner' -Tag 'Remove-IMPartner' {
        It 'Should remove the partner created by this test' {
            if (-not $script:PartnerCreatedByTest)
            {
                Set-ItResult -Skipped -Because 'Partnership was not created by this test'
                return
            }
            Remove-IMPartner -id $script:PartnerId
            $script:PartnerCreatedByTest = $false
            Get-IMPartner -Direction shared-by | Select-Object -ExpandProperty id | Should -Not -Contain $script:PartnerId
        }
        It 'Should throw when the partnership does not exist' {
            { Remove-IMPartner -id ([guid]::NewGuid().ToString()) } | Should -Throw
        }
    }
}
