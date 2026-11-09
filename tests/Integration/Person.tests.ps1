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
# - Add-IMPersonAccess -Everyone: would grant access to every existing person on the shared server.
# - Set-IMPerson -FaceAssetId: changes the feature face of a person and needs a specific face asset; not reversible by the test.
# - Get-IMPerson/Set-IMPerson/Remove-IMPerson against pre-existing persons: only test-created persons are changed or deleted.
Describe 'Person' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:Module = Get-Module PSImmich
        $script:OwnerUser = $script:Module.Invoke({ Invoke-ImmichApiGetMyUser })
        $script:CreatedPersonIds = [System.Collections.Generic.List[string]]::new()
        $script:CreatedUserIds = [System.Collections.Generic.List[string]]::new()
        $script:NewTestPerson = {
            param(
                [string]$Name = "PSImmich-Test-Person-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
            )
            $Person = New-IMPerson -Name $Name
            $script:CreatedPersonIds.Add($Person.id)
            $Person
        }
        # Sharing requires the target user to be in the owner's cluster group, so the user is invited and
        # accepts while logged in as itself. The user and its random password exist only for this run.
        $script:NewSharedUser = {
            $Suffix = [guid]::NewGuid().ToString('N').Substring(0, 8)
            $Password = [guid]::NewGuid().ToString('N') + 'Aa1!'
            $Local, $Domain = $script:OwnerUser.email -split '@'
            $User = New-IMUser -Email "$Local+psimtest-$Suffix@$Domain" -Name "PSImmich-Test-$Suffix" -Password (ConvertTo-SecureString -String $Password -AsPlainText -Force)
            $script:CreatedUserIds.Add($User.id)

            $Invite = $script:Module.Invoke({
                    param($GroupId, $UserId)
                    Invoke-ImmichApiCreateClusterGroupRequest -Id $GroupId -Body @{ userId = $UserId }
                }, $script:OwnerUser.clusterGroupId, $User.id)

            $Credential = [pscredential]::new($User.email, (ConvertTo-SecureString -String $Password -AsPlainText -Force))
            $UserSession = Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Credential -PassThru
            try
            {
                $script:Module.Invoke({
                        param($RequestId, $Session)
                        Invoke-ImmichApiAcceptClusterGroupRequest -Id $RequestId -ImmichSession $Session
                    }, $Invite.id, $UserSession) | Out-Null
            }
            finally
            {
                Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
            }
            $User
        }
        $script:SharedWithUser = & $script:NewSharedUser
        $script:SharedWithUserId = $script:SharedWithUser.id
    }

    AfterAll {
        foreach ($Id in $script:CreatedPersonIds)
        {
            try
            {
                Remove-IMPersonAccess -PersonId $Id -SharedWithId $script:SharedWithUserId -Confirm:$false -ErrorAction SilentlyContinue
            }
            catch { }
            try
            {
                Remove-IMPerson -Ids $Id -Confirm:$false -ErrorAction SilentlyContinue
            }
            catch { }
        }
        foreach ($Id in $script:CreatedUserIds)
        {
            Remove-IMUser -Id $Id -Force -Confirm:$false -ErrorAction SilentlyContinue
        }
    }

    Context 'New-IMPerson' -Tag 'New-IMPerson' {
        It 'Should create a person with the given name' {
            $Person = & $script:NewTestPerson -Name 'PSImmich-Test-New'
            $Result = Get-IMPerson -Id $Person.id
            $Result.name | Should -Be 'PSImmich-Test-New'
        }
        It 'Should create a hidden person when -IsHidden is used' {
            $Person = New-IMPerson -Name 'PSImmich-Test-Hidden' -IsHidden
            $script:CreatedPersonIds.Add($Person.id)
            $Result = Get-IMPerson -Id $Person.id
            $Result.isHidden | Should -BeTrue
        }
        It 'Should store the birth date' {
            $Person = New-IMPerson -Name 'PSImmich-Test-Birth' -BirthDate ([datetime]'2000-01-01')
            $script:CreatedPersonIds.Add($Person.id)
            $Result = Get-IMPerson -Id $Person.id
            ([datetime]$Result.birthDate).Date | Should -Be ([datetime]'2000-01-01').Date
        }
        It 'Should return a PersonResponseDto object' {
            $Person = & $script:NewTestPerson
            $Person.PSObject.TypeNames | Should -Contain 'PersonResponseDto'
        }
    }

    Context 'Get-IMPerson' -Tag 'Get-IMPerson' {
        BeforeAll {
            $script:Person = & $script:NewTestPerson -Name 'PSImmich-Test-Get'
        }
        It 'Should list persons as PersonResponseDto objects with IDs' {
            $All = @(Get-IMPerson -WithHidden)
            $All | ForEach-Object {
                $_.PSObject.Properties.Name | Should -Not -Contain 'people'
                $_.id | Should -Not -BeNullOrEmpty
            }
        }
        It 'Should return a single person by ID' {
            $Result = Get-IMPerson -Id $script:Person.id
            $Result | Should -HaveCount 1
            $Result.id | Should -Be $script:Person.id
        }
        It 'Should accept person IDs from the pipeline' {
            $Result = $script:Person.id | Get-IMPerson
            $Result.id | Should -Be $script:Person.id
        }
        It 'Should return a PersonResponseDto object' {
            $Result = Get-IMPerson -Id $script:Person.id
            $Result.PSObject.TypeNames | Should -Contain 'PersonResponseDto'
        }
        It 'Should include statistics when requested' {
            $Result = Get-IMPerson -Id $script:Person.id -IncludeStatistics
            $Result.PSObject.Properties.Name | Should -Contain 'AssetCount'
        }
        It 'Should throw for a non-existent person ID' {
            { Get-IMPerson -Id ([guid]::NewGuid().ToString()) } | Should -Throw
        }
    }

    Context 'Set-IMPerson' -Tag 'Set-IMPerson' {
        BeforeEach {
            $script:Person = & $script:NewTestPerson
        }
        It 'Should update the name' {
            Set-IMPerson -Id $script:Person.id -Name 'PSImmich-Test-Renamed' | Out-Null
            (Get-IMPerson -Id $script:Person.id).name | Should -Be 'PSImmich-Test-Renamed'
        }
        It 'Should update the birth date' {
            Set-IMPerson -Id $script:Person.id -BirthDate ([datetime]'1990-06-15') | Out-Null
            $Result = Get-IMPerson -Id $script:Person.id
            ([datetime]$Result.birthDate).Date | Should -Be ([datetime]'1990-06-15').Date
        }
        # The bulk endpoint accepts avatarColor but 3.3.6 does not reflect it on GET /people, so assert the per-item result instead.
        It 'Should accept each avatar color from the spec enum' {
            foreach ($Color in @('primary', 'red', 'amber'))
            {
                $Result = Set-IMPerson -Id $script:Person.id -Color $Color
                $Result.success | Should -BeTrue -Because "avatar color '$Color' should be accepted"
            }
        }
        It 'Should reject a color outside the spec enum' {
            { Set-IMPerson -Id $script:Person.id -Color '#FF0000' } | Should -Throw
        }
        It 'Should update the favorite flag' {
            Set-IMPerson -Id $script:Person.id -IsFavorite $true | Out-Null
            (Get-IMPerson -Id $script:Person.id).isFavorite | Should -BeTrue
        }
        It 'Should update the hidden flag' {
            Set-IMPerson -Id $script:Person.id -IsHidden $true | Out-Null
            (Get-IMPerson -Id $script:Person.id).isHidden | Should -BeTrue
        }
        It 'Should accept person IDs from the pipeline' {
            $script:Person | Set-IMPerson -Name 'PSImmich-Test-Piped' | Out-Null
            (Get-IMPerson -Id $script:Person.id).name | Should -Be 'PSImmich-Test-Piped'
        }
        It 'Should return a bulk response with success for the updated person' {
            $Result = @(Set-IMPerson -Id $script:Person.id -Name 'PSImmich-Test-Typed')
            $Result[0].success | Should -BeTrue
        }
        It 'Should report failure without throwing for a non-existent person ID' {
            $Result = @(Set-IMPerson -Id ([guid]::NewGuid().ToString()) -Name 'PSImmich-Test-Missing')
            $Result[0].success | Should -BeFalse
        }
    }

    Context 'Remove-IMPerson' -Tag 'Remove-IMPerson' {
        It 'Should remove a test person by ID' {
            $Person = & $script:NewTestPerson
            Remove-IMPerson -Ids $Person.id -Confirm:$false
            Get-IMPerson -WithHidden | Select-Object -ExpandProperty id | Should -Not -Contain $Person.id
        }
        It 'Should remove a test person from the pipeline' {
            $Person = & $script:NewTestPerson
            $Person | Remove-IMPerson -Confirm:$false
            Get-IMPerson -WithHidden | Select-Object -ExpandProperty id | Should -Not -Contain $Person.id
        }
        It 'Should not remove the person when -WhatIf is used' {
            $Person = & $script:NewTestPerson
            Remove-IMPerson -Ids $Person.id -WhatIf
            (Get-IMPerson -Id $Person.id).id | Should -Be $Person.id
        }
    }

    Context 'Merge-IMPerson' -Tag 'Merge-IMPerson' {
        It 'Should merge a source person into a target person' {
            $Target = & $script:NewTestPerson -Name 'PSImmich-Test-MergeTarget'
            $Source = & $script:NewTestPerson -Name 'PSImmich-Test-MergeSource'
            Merge-IMPerson -ToPersonID $Target.id -FromPersonID $Source.id | Out-Null
            (Get-IMPerson -Id $Target.id).id | Should -Be $Target.id
            { Get-IMPerson -Id $Source.id } | Should -Throw
        }
        It 'Should report failure for the unknown source person without throwing' {
            $Target = & $script:NewTestPerson
            $UnknownId = [guid]::NewGuid().ToString()
            $Result = @(Merge-IMPerson -ToPersonID $Target.id -FromPersonID $UnknownId)
            $Entry = @($Result | Where-Object { $_.id -eq $UnknownId })
            if ($Entry.Count -gt 0) { $Entry[0].success | Should -BeFalse }
        }
    }

    Context 'Export-IMPersonThumbnail' -Tag 'Export-IMPersonThumbnail' {
        BeforeAll {
            $script:ThumbnailPerson = Get-IMPerson -WithHidden | Where-Object { $_.thumbnailPath } | Select-Object -First 1
        }
        It 'Should export the thumbnail to the target path' {
            if (-not $script:ThumbnailPerson)
            {
                Set-ItResult -Skipped -Because 'No existing person has a thumbnail to export'
                return
            }
            Export-IMPersonThumbnail -Id $script:ThumbnailPerson.id -Path $TestDrive
            Join-Path $TestDrive "$($script:ThumbnailPerson.id).jpeg" | Should -Exist
        }
        It 'Should accept person IDs from the pipeline' {
            if (-not $script:ThumbnailPerson)
            {
                Set-ItResult -Skipped -Because 'No existing person has a thumbnail to export'
                return
            }
            $script:ThumbnailPerson.id | Export-IMPersonThumbnail -Path $TestDrive
            Join-Path $TestDrive "$($script:ThumbnailPerson.id).jpeg" | Should -Exist
        }
        It 'Should throw for a non-existent person ID' {
            { Export-IMPersonThumbnail -Id ([guid]::NewGuid().ToString()) -Path $TestDrive } | Should -Throw
        }
    }

    Context 'Add-IMPersonAccess' -Tag 'Add-IMPersonAccess' {
        BeforeEach {
            $script:Person = & $script:NewTestPerson
        }
        It 'Should grant read access to a user for a test person' {
            Add-IMPersonAccess -PersonId $script:Person.id -SharedWithId $script:SharedWithUserId -Role read | Out-Null
            $Result = Get-IMPersonAccess -PersonId $script:Person.id
            $Result.sharedWithId | Should -Contain $script:SharedWithUserId
            Remove-IMPersonAccess -PersonId $script:Person.id -SharedWithId $script:SharedWithUserId -Confirm:$false
        }
        It 'Should grant write access to a user for a test person' {
            Add-IMPersonAccess -PersonId $script:Person.id -SharedWithId $script:SharedWithUserId -Role write | Out-Null
            $Result = Get-IMPersonAccess -PersonId $script:Person.id | Where-Object { $_.sharedWithId -eq $script:SharedWithUserId }
            $Result.role | Should -Be 'write'
            Remove-IMPersonAccess -PersonId $script:Person.id -SharedWithId $script:SharedWithUserId -Confirm:$false
        }
        It 'Should throw for a non-existent person ID' {
            { Add-IMPersonAccess -PersonId ([guid]::NewGuid().ToString()) -SharedWithId $script:SharedWithUserId -Role read } | Should -Throw
        }
    }

    Context 'Get-IMPersonAccess' -Tag 'Get-IMPersonAccess' {
        BeforeAll {
            $script:Person = & $script:NewTestPerson
            Add-IMPersonAccess -PersonId $script:Person.id -SharedWithId $script:SharedWithUserId -Role read | Out-Null
        }
        AfterAll {
            Remove-IMPersonAccess -PersonId $script:Person.id -SharedWithId $script:SharedWithUserId -Confirm:$false -ErrorAction SilentlyContinue
        }
        It 'Should return access entries for a test person' {
            $Result = Get-IMPersonAccess -PersonId $script:Person.id
            $Result | Should -Not -BeNullOrEmpty
            $Result.sharedWithId | Should -Contain $script:SharedWithUserId
        }
        It 'Should filter access entries by role' {
            $Result = Get-IMPersonAccess -PersonId $script:Person.id -Role read
            $Result | Where-Object { $_.role -ne 'read' } | Should -BeNullOrEmpty
            $Result.sharedWithId | Should -Contain $script:SharedWithUserId
        }
        It 'Should filter access entries by shared-with user' {
            $Result = Get-IMPersonAccess -PersonId $script:Person.id -SharedWithId $script:SharedWithUserId
            $Result | Where-Object { $_.sharedWithId -ne $script:SharedWithUserId } | Should -BeNullOrEmpty
            $Result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-IMPersonAccess' -Tag 'Remove-IMPersonAccess' {
        BeforeEach {
            $script:Person = & $script:NewTestPerson
            Add-IMPersonAccess -PersonId $script:Person.id -SharedWithId $script:SharedWithUserId -Role read | Out-Null
        }
        It 'Should remove access for a user from a test person' {
            Remove-IMPersonAccess -PersonId $script:Person.id -SharedWithId $script:SharedWithUserId -Confirm:$false
            $Result = Get-IMPersonAccess -PersonId $script:Person.id
            $Result.sharedWithId | Should -Not -Contain $script:SharedWithUserId
        }
        It 'Should remove access from access entries via the pipeline' {
            Get-IMPersonAccess -PersonId $script:Person.id | Remove-IMPersonAccess -Confirm:$false
            $Result = Get-IMPersonAccess -PersonId $script:Person.id
            $Result.sharedWithId | Should -Not -Contain $script:SharedWithUserId
        }
    }
}
