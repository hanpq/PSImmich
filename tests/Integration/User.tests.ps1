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

Describe 'User' -Tag 'Integration' {
    # Intentionally excluded: New-IMUser, Remove-IMUser, Restore-IMUser and Set-IMUser (create, delete or change real accounts),
    # Add-IMMyProfilePicture and Remove-IMMyProfilePicture (change the profile picture of the live account).
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $Me = Get-IMUser -Me
        $MyId = $Me.id
        $ExportPath = Join-Path $PSScriptRoot 'ProfileExport'
        New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
    }
    AfterAll {
        Remove-Item -Path $ExportPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context 'Get-IMUser' -Tag 'Get-IMUser' {
        It 'Should list all users as UserAdminResponseDto' {
            $Result = Get-IMUser
            $Result | Should -Not -BeNullOrEmpty
            $Result[0].GetType().Name | Should -Be 'UserAdminResponseDto'
        }
        It 'Should include the current user in the list' {
            (Get-IMUser).id | Should -Contain $MyId
        }
        It 'Should return more or equal users when including deleted users' {
            $All = Get-IMUser -IncludeDeleted
            $Active = Get-IMUser
            $All.Count | Should -BeGreaterOrEqual $Active.Count
        }
        It 'Should return one user when using -Id' {
            $Result = Get-IMUser -Id $MyId
            $Result | Should -HaveCount 1
            $Result.id | Should -Be $MyId
        }
        It 'Should return multiple users when given multiple ids' {
            $Result = Get-IMUser -Id $MyId, $MyId
            $Result | Should -HaveCount 2
        }
        It 'Should accept a user id from the pipeline' {
            $Result = $MyId | Get-IMUser
            $Result | Should -HaveCount 1
            $Result.id | Should -Be $MyId
        }
        It 'Should return the current user when using -Me' {
            $Result = Get-IMUser -Me
            $Result | Should -HaveCount 1
            $Result.GetType().Name | Should -Be 'UserResponseDto'
            $Result.id | Should -Be $MyId
            $Result.email | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-IMUserPreference' -Tag 'Get-IMUserPreference' {
        It 'Should return one preferences object for the current user' {
            $Result = Get-IMUserPreference
            $Result | Should -HaveCount 1
            $Result.GetType().Name | Should -Be 'UserPreferencesResponseDto'
        }
        It 'Should contain the <_> preference group' -ForEach @(
            'albums', 'folders', 'memories', 'people', 'sharedLinks', 'ratings',
            'tags', 'emailNotifications', 'download', 'purchase', 'cast'
        ) {
            (Get-IMUserPreference).PSObject.Properties.Name | Should -Contain $_
        }
        It 'Should return preferences when using -Id' {
            $Result = Get-IMUserPreference -Id $MyId
            $Result | Should -HaveCount 1
            $Result.GetType().Name | Should -Be 'UserPreferencesResponseDto'
        }
        It 'Should accept a user id from the pipeline' {
            $Result = $MyId | Get-IMUserPreference
            $Result | Should -HaveCount 1
        }
    }

    Context 'Get-IMUserSession' -Tag 'Get-IMUserSession' {
        It 'Should not throw for a user id' {
            { Get-IMUserSession -Id $MyId } | Should -Not -Throw
        }
        It 'Should return SessionResponseDto objects' {
            $Result = Get-IMUserSession -Id $MyId
            $Result | ForEach-Object { $_.GetType().Name | Should -Be 'SessionResponseDto' }
        }
        It 'Should accept a user id from the pipeline' {
            { $MyId | Get-IMUserSession } | Should -Not -Throw
        }
        It 'Should throw for a malformed id' {
            { Get-IMUserSession -Id 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Get-IMUserStatistic' -Tag 'Get-IMUserStatistic' {
        It 'Should return statistics for a user' {
            $Result = Get-IMUserStatistic -Id $MyId
            $Result | Should -Not -BeNullOrEmpty
        }
        It 'Should contain the <_> statistic' -ForEach @('images', 'videos', 'total') {
            (Get-IMUserStatistic -Id $MyId).PSObject.Properties.Name | Should -Contain $_
        }
        It 'Should return non-negative counts' {
            $Result = Get-IMUserStatistic -Id $MyId
            $Result.total | Should -BeGreaterOrEqual 0
        }
        It 'Should accept a user id from the pipeline' {
            $Result = $MyId | Get-IMUserStatistic
            $Result.total | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Export-IMProfilePicture' -Tag 'Export-IMProfilePicture' {
        It 'Should export the profile picture of a user to the path' {
            if (-not $Me.profileImagePath)
            {
                Set-ItResult -Skipped -Because 'Current user has no profile picture'
                return
            }
            Export-IMProfilePicture -Id $MyId -Path $ExportPath
            $File = Join-Path $ExportPath "$MyId.jpeg"
            $File | Should -Exist
            (Get-Item -LiteralPath $File).Length | Should -BeGreaterThan 0
        }
        It 'Should accept a user id from the pipeline' {
            if (-not $Me.profileImagePath)
            {
                Set-ItResult -Skipped -Because 'Current user has no profile picture'
                return
            }
            $MyId | Export-IMProfilePicture -Path $ExportPath
            Join-Path $ExportPath "$MyId.jpeg" | Should -Exist
        }
        It 'Should throw for a malformed id' {
            { Export-IMProfilePicture -Id 'not-a-guid' -Path $ExportPath } | Should -Throw
        }
    }

    Context 'Set-IMUserPreference' -Tag 'Set-IMUserPreference' {
        BeforeAll {
            [bool]$OriginalEmailEnabled = (Get-IMUserPreference).emailNotifications.enabled
        }
        AfterEach {
            Set-IMUserPreference -Id $MyId -EmailNotificationEnabled:$OriginalEmailEnabled | Out-Null
        }
        It 'Should change EmailNotificationEnabled for the given id' {
            $Target = -not $OriginalEmailEnabled
            Set-IMUserPreference -Id $MyId -EmailNotificationEnabled:$Target | Out-Null
            (Get-IMUserPreference).emailNotifications.enabled | Should -Be $Target
        }
        It 'Should return UserPreferencesResponseDto' {
            $Target = -not $OriginalEmailEnabled
            $Result = Set-IMUserPreference -Id $MyId -EmailNotificationEnabled:$Target
            $Result.GetType().Name | Should -Be 'UserPreferencesResponseDto'
        }
        It 'Should change EmailNotificationEnabled when the id comes from the pipeline' {
            $Target = -not $OriginalEmailEnabled
            $MyId | Set-IMUserPreference -EmailNotificationEnabled:$Target | Out-Null
            (Get-IMUserPreference).emailNotifications.enabled | Should -Be $Target
        }
        It 'Should not change the preference when using -WhatIf' {
            $Target = -not $OriginalEmailEnabled
            Set-IMUserPreference -Id $MyId -EmailNotificationEnabled:$Target -WhatIf
            (Get-IMUserPreference).emailNotifications.enabled | Should -Be $OriginalEmailEnabled
        }
        It 'Should reject an AvatarColor outside the allowed values' {
            { Set-IMUserPreference -Id $MyId -AvatarColor 'magenta' } | Should -Throw
        }
        It 'Should throw for a malformed id' {
            { Set-IMUserPreference -Id 'not-a-guid' -EmailNotificationEnabled:$true } | Should -Throw
        }
    }
}
