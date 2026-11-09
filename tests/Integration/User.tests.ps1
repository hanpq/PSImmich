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
    # Intentionally excluded: Set-IMUser -Password and -QuotaSizeInBytes, and Remove-IMUser -Force (not reversible by the test).
    # User changes are limited to the persistent psimtest-persistent-* accounts and are always reverted.
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $Me = Get-IMUser -Me
        $MyId = $Me.id
        $ExportPath = Join-Path $PSScriptRoot 'ProfileExport'
        New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null

        # Persistent accounts that survive between runs. They are created once and reused. A trashed one is restored first.
        $Local, $Domain = $Me.email -split '@'
        $script:PersistentUsers = foreach ($Index in 1..2)
        {
            $PersistentEmail = "$Local+psimtest-persistent-$Index@$Domain"
            $Existing = Get-IMUser -IncludeDeleted | Where-Object email -eq $PersistentEmail | Select-Object -First 1
            if ($Existing)
            {
                if ($Existing.deletedAt)
                {
                    Restore-IMUser -Id $Existing.id | Out-Null
                }
                $Existing
            }
            else
            {
                $Password = [guid]::NewGuid().ToString('N') + 'Aa1!'
                New-IMUser -Email $PersistentEmail -Name "PSImmich-Persistent-$Index" -Password (ConvertTo-SecureString -String $Password -AsPlainText -Force) -Notify:$false
            }
        }
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

    # Restores the account's original picture, or removes the test picture when the account had none.
    Context 'Add-IMMyProfilePicture and Remove-IMMyProfilePicture' -Tag 'Add-IMMyProfilePicture' {
        BeforeAll {
            $script:HadPicture = [bool]$Me.profileImagePath
            $script:BackupFolder = Join-Path ([System.IO.Path]::GetTempPath()) "psimtest-profile-$([guid]::NewGuid().ToString('N'))"
            New-Item -Path $script:BackupFolder -ItemType Directory -Force | Out-Null
            $script:BackupFile = $null
            if ($script:HadPicture)
            {
                Export-IMProfilePicture -Id $MyId -Path $script:BackupFolder
                $script:BackupFile = Join-Path $script:BackupFolder "$MyId.jpeg"
            }
            $script:Fixture = Join-Path $PSScriptRoot 'Immich.png'
            $script:VerifyFolder = Join-Path $script:BackupFolder 'verify'
            New-Item -Path $script:VerifyFolder -ItemType Directory -Force | Out-Null
        }

        AfterAll {
            try
            {
                $Current = (Get-IMUser -Me).profileImagePath
                if ($script:HadPicture)
                {
                    Add-IMMyProfilePicture -FilePath $script:BackupFile
                }
                elseif ($Current)
                {
                    Remove-IMMyProfilePicture -Confirm:$false
                }
            }
            finally
            {
                Remove-Item -Path $script:BackupFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Should set the profile picture of the current user' {
            Add-IMMyProfilePicture -FilePath $script:Fixture
            (Get-IMUser -Me).profileImagePath | Should -Not -BeNullOrEmpty
        }

        It 'Should export the uploaded profile picture' {
            Export-IMProfilePicture -Id $MyId -Path $script:VerifyFolder
            $File = Join-Path $script:VerifyFolder "$MyId.jpeg"
            $File | Should -Exist
            (Get-Item -LiteralPath $File).Length | Should -BeGreaterThan 0
        }

        It 'Should not remove the profile picture with -WhatIf' {
            Remove-IMMyProfilePicture -WhatIf
            (Get-IMUser -Me).profileImagePath | Should -Not -BeNullOrEmpty
        }

        It 'Should remove the profile picture of the current user' {
            Remove-IMMyProfilePicture -Confirm:$false
            (Get-IMUser -Me).profileImagePath | Should -BeNullOrEmpty
        }
    }

    Context 'New-IMUser' -Tag 'New-IMUser' {
        It 'Should have the persistent test users available and active' {
            $script:PersistentUsers | Should -HaveCount 2
            foreach ($User in $script:PersistentUsers)
            {
                (Get-IMUser -Id $User.id).email | Should -Be $User.email
            }
        }
    }

    # Only the persistent psimtest-persistent-* accounts are changed. Every change is restored in finally or AfterAll.
    Context 'Set-IMUser' -Tag 'Set-IMUser' {
        BeforeAll {
            $script:Target = $script:PersistentUsers[0]
            $script:TargetId = $script:Target.id
            $Original = Get-IMUser -Id $script:TargetId
            $script:OriginalName = $Original.name
            $script:OriginalShouldChangePassword = [bool]$Original.shouldChangePassword
        }

        AfterAll {
            Set-IMUser -Id $script:TargetId -Name $script:OriginalName -ShouldChangePassword:$script:OriginalShouldChangePassword -Confirm:$false
        }

        It 'Should update the name and restore the original name' {
            $Marker = "PSImmich-Renamed-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
            try
            {
                Set-IMUser -Id $script:TargetId -Name $Marker -Confirm:$false
                (Get-IMUser -Id $script:TargetId).name | Should -BeExactly $Marker
            }
            finally
            {
                Set-IMUser -Id $script:TargetId -Name $script:OriginalName -Confirm:$false
            }
            (Get-IMUser -Id $script:TargetId).name | Should -BeExactly $script:OriginalName
        }

        It 'Should set ShouldChangePassword to true and back to the original value' {
            try
            {
                Set-IMUser -Id $script:TargetId -ShouldChangePassword:$true -Confirm:$false
                (Get-IMUser -Id $script:TargetId).shouldChangePassword | Should -BeTrue
            }
            finally
            {
                Set-IMUser -Id $script:TargetId -ShouldChangePassword:$script:OriginalShouldChangePassword -Confirm:$false
            }
            [bool](Get-IMUser -Id $script:TargetId).shouldChangePassword | Should -Be $script:OriginalShouldChangePassword
        }

        It 'Should accept the user id from the pipeline' {
            $Marker = "PSImmich-Piped-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
            try
            {
                [pscustomobject]@{ id = $script:TargetId } | Set-IMUser -Name $Marker -Confirm:$false
                (Get-IMUser -Id $script:TargetId).name | Should -BeExactly $Marker
            }
            finally
            {
                Set-IMUser -Id $script:TargetId -Name $script:OriginalName -Confirm:$false
            }
        }

        It 'Should not change the user with -WhatIf' {
            Set-IMUser -Id $script:TargetId -Name 'PSImmich-WhatIf-Marker' -WhatIf
            (Get-IMUser -Id $script:TargetId).name | Should -BeExactly $script:OriginalName
        }

        It 'Should throw for a malformed id' {
            { Set-IMUser -Id 'not-a-guid' -Name 'PSImmich-Invalid' -Confirm:$false } | Should -Throw
        }
    }

    # Remove-IMUser without -Force only moves the account to trash. Restore-IMUser brings it back.
    Context 'Remove-IMUser and Restore-IMUser' -Tag 'Remove-IMUser' {
        BeforeAll {
            $script:RemoveTargetId = $script:PersistentUsers[1].id
        }

        AfterAll {
            $Current = Get-IMUser -IncludeDeleted | Where-Object id -eq $script:RemoveTargetId
            if ($Current.deletedAt)
            {
                Restore-IMUser -Id $script:RemoveTargetId | Out-Null
            }
        }

        It 'Should not remove the user with -WhatIf' {
            Remove-IMUser -Id $script:RemoveTargetId -WhatIf
            (Get-IMUser | Where-Object id -eq $script:RemoveTargetId) | Should -Not -BeNullOrEmpty
        }

        It 'Should move the user to trash without permanently deleting it' {
            Remove-IMUser -Id $script:RemoveTargetId -Confirm:$false
            $Trashed = Get-IMUser -IncludeDeleted | Where-Object id -eq $script:RemoveTargetId
            ([datetime]$Trashed.deletedAt).Year | Should -BeGreaterThan 1
            Get-IMUser | Where-Object id -eq $script:RemoveTargetId | Should -BeNullOrEmpty
        }

        It 'Should restore the user from trash' {
            Restore-IMUser -Id $script:RemoveTargetId | Out-Null
            (Get-IMUser | Where-Object id -eq $script:RemoveTargetId) | Should -Not -BeNullOrEmpty
            # The server reports 0001-01-01 instead of null for an account that is not in trash.
            ([datetime](Get-IMUser -IncludeDeleted | Where-Object id -eq $script:RemoveTargetId).deletedAt).Year | Should -Be 1
        }

        It 'Should throw for a malformed id' {
            { Remove-IMUser -Id 'not-a-guid' -Confirm:$false } | Should -Throw
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
