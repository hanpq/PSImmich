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

Describe 'APIKey' -Tag 'Integration' {
    # Intentionally excluded: Reset-IMAPIKey (rotates the secret of a key that a live session may depend on).
    # Pre-existing keys are never read, renamed or removed. Only keys created by these tests are changed.
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:CreatedKeyIds = [System.Collections.Generic.List[string]]::new()
        $Prefix = "PSLiveTest-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
    }
    AfterAll {
        foreach ($Id in $script:CreatedKeyIds)
        {
            try
            {
                Remove-IMAPIKey -Id $Id -Confirm:$false -ErrorAction Stop
            }
            catch
            {
                Write-Warning "Cleanup failed for test API key ${Id}: $($_.Exception.Message)"
            }
        }
    }

    Context 'Get-IMAPIKey' -Tag 'Get-IMAPIKey' {
        It 'Should list API keys' {
            $Result = @(Get-IMAPIKey)
            $Result.Count | Should -BeGreaterThan 0
        }
        It 'Should return objects with an id and name' {
            $Result = @(Get-IMAPIKey)
            $Result | Where-Object { -not $_.id -or -not $_.name } | Should -BeNullOrEmpty
        }
        It 'Should retrieve one API key when using -Id' {
            $Name = "$Prefix-get"
            $Created = New-IMAPIKey -Name $Name -Permission all
            $script:CreatedKeyIds.Add($Created.apiKey.id)
            $Result = Get-IMAPIKey -Id $Created.apiKey.id
            $Result | Should -HaveCount 1
            $Result.id | Should -Be $Created.apiKey.id
            $Result.name | Should -Be $Name
        }
        It 'Should accept an id from the pipeline' {
            $Name = "$Prefix-pipe"
            $Created = New-IMAPIKey -Name $Name -Permission all
            $script:CreatedKeyIds.Add($Created.apiKey.id)
            $Result = $Created.apiKey.id | Get-IMAPIKey
            $Result | Should -HaveCount 1
            $Result.id | Should -Be $Created.apiKey.id
        }
        It 'Should throw for a malformed id' {
            { Get-IMAPIKey -Id 'not-a-guid' } | Should -Throw
        }
    }

    Context 'New-IMAPIKey' -Tag 'New-IMAPIKey' {
        It 'Should create a new API key with a secret' {
            $Name = "$Prefix-new"
            $Result = New-IMAPIKey -Name $Name -Permission all
            $script:CreatedKeyIds.Add($Result.apiKey.id)
            $Result.secret | Should -Not -BeNullOrEmpty
            $Result.apiKey.name | Should -Be $Name
            (Get-IMAPIKey).id | Should -Contain $Result.apiKey.id
        }
        It 'Should create a new API key with multiple permissions' {
            $Result = New-IMAPIKey -Name "$Prefix-multi" -Permission 'activity.create', 'activity.read', 'activity.update'
            $script:CreatedKeyIds.Add($Result.apiKey.id)
            $Result.secret | Should -Not -BeNullOrEmpty
            Get-IMAPIKey -Id $Result.apiKey.id | Should -HaveCount 1
        }
        It 'Should default to the all permission' {
            $Result = New-IMAPIKey -Name "$Prefix-default"
            $script:CreatedKeyIds.Add($Result.apiKey.id)
            $Result.apiKey.permissions | Should -Contain 'all'
        }
        It 'Should reject an unknown permission' {
            { New-IMAPIKey -Name "$Prefix-bad" -Permission 'not.a.permission' } | Should -Throw
        }
    }

    Context 'Rename-IMAPIKey' -Tag 'Rename-IMAPIKey' {
        It 'Should set a new name by id' {
            $Created = New-IMAPIKey -Name "$Prefix-rename" -Permission all
            $script:CreatedKeyIds.Add($Created.apiKey.id)
            Rename-IMAPIKey -Id $Created.apiKey.id -Name "$Prefix-renamed"
            (Get-IMAPIKey -Id $Created.apiKey.id).name | Should -Be "$Prefix-renamed"
        }
        It 'Should set a new name when the key comes from the pipeline' {
            $Created = New-IMAPIKey -Name "$Prefix-pipe-rename" -Permission all
            $script:CreatedKeyIds.Add($Created.apiKey.id)
            Get-IMAPIKey -Id $Created.apiKey.id | Rename-IMAPIKey -Name "$Prefix-pipe-renamed"
            (Get-IMAPIKey -Id $Created.apiKey.id).name | Should -Be "$Prefix-pipe-renamed"
        }
    }

    Context 'Remove-IMAPIKey' -Tag 'Remove-IMAPIKey' {
        It 'Should remove the API key' {
            $Created = New-IMAPIKey -Name "$Prefix-remove" -Permission all
            Remove-IMAPIKey -Id $Created.apiKey.id -Confirm:$false
            (Get-IMAPIKey).id | Should -Not -Contain $Created.apiKey.id
        }
        It 'Should not remove the API key when using -WhatIf' {
            $Created = New-IMAPIKey -Name "$Prefix-remove-whatif" -Permission all
            $script:CreatedKeyIds.Add($Created.apiKey.id)
            Remove-IMAPIKey -Id $Created.apiKey.id -WhatIf
            (Get-IMAPIKey).id | Should -Contain $Created.apiKey.id
        }
        It 'Should throw when the key does not exist' {
            { Remove-IMAPIKey -Id ([guid]::NewGuid().ToString()) -Confirm:$false } | Should -Throw
        }
    }
}
