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
# - Sync-IMLibrary: scans the server filesystem and starts server-side jobs, which affects the shared server.
Describe 'Library' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:OwnerId = (Get-IMUser -Me).id
        $script:ImportPath = '/mnt/media/pictures'
        $script:CreatedLibraryIds = [System.Collections.Generic.List[string]]::new()
        $script:NewTestLibrary = {
            param(
                [string]$Name = "PSImmich-Test-Library-$([guid]::NewGuid().ToString('N').Substring(0, 8))",
                [string[]]$ExclusionPatterns = @('*/*')
            )
            $Library = New-IMLibrary -Name $Name -ImportPaths $script:ImportPath -ExclusionPatterns $ExclusionPatterns -OwnerId $script:OwnerId
            $script:CreatedLibraryIds.Add($Library.id)
            $Library
        }
    }

    AfterAll {
        foreach ($Id in $script:CreatedLibraryIds)
        {
            Remove-IMLibrary -Id $Id -Confirm:$false -ErrorAction SilentlyContinue
        }
    }

    Context 'New-IMLibrary' -Tag 'New-IMLibrary' {
        It 'Should create a library with the given name, import path and owner' {
            $Library = & $script:NewTestLibrary -Name 'PSImmich-Test-New'
            $Library.name | Should -Be 'PSImmich-Test-New'
            $Library.importPaths | Should -Contain $script:ImportPath
            $Library.ownerId | Should -Be $script:OwnerId
        }
        It 'Should store exclusion patterns' {
            $Library = & $script:NewTestLibrary
            $Library.exclusionPatterns | Should -Contain '*/*'
        }
        It 'Should return a LibraryResponseDto object' {
            $Library = & $script:NewTestLibrary
            $Library.PSObject.TypeNames | Should -Contain 'LibraryResponseDto'
        }
        It 'Should throw when the owner ID is not a GUID' {
            { New-IMLibrary -Name 'PSImmich-Test-Invalid' -ImportPaths $script:ImportPath -OwnerId 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Get-IMLibrary' -Tag 'Get-IMLibrary' {
        BeforeAll {
            $script:Library = & $script:NewTestLibrary
        }
        It 'Should list all libraries including the test library' {
            $All = Get-IMLibrary
            $All.id | Should -Contain $script:Library.id
        }
        It 'Should filter the list by owner' {
            $Owned = Get-IMLibrary -OwnerId $script:OwnerId
            $Owned.id | Should -Contain $script:Library.id
            $Owned | Where-Object { $_.ownerId -ne $script:OwnerId } | Should -BeNullOrEmpty
        }
        It 'Should return a single library by ID' {
            $Result = Get-IMLibrary -Id $script:Library.id
            $Result | Should -HaveCount 1
            $Result.id | Should -Be $script:Library.id
        }
        It 'Should accept library IDs from the pipeline' {
            $Result = $script:Library.id | Get-IMLibrary
            $Result | Should -HaveCount 1
            $Result.id | Should -Be $script:Library.id
        }
        It 'Should return a LibraryResponseDto object' {
            $Result = Get-IMLibrary -Id $script:Library.id
            $Result.PSObject.TypeNames | Should -Contain 'LibraryResponseDto'
        }
        It 'Should include statistics when requested' {
            $Result = Get-IMLibrary -Id $script:Library.id -IncludeStatistics
            $Result.PSObject.Properties.Name | Should -Contain 'Statistics'
            $Result.Statistics | Should -Not -BeNullOrEmpty
        }
        It 'Should throw for a non-existent library ID' {
            { Get-IMLibrary -Id ([guid]::NewGuid().ToString()) } | Should -Throw
        }
    }

    Context 'Set-IMLibrary' -Tag 'Set-IMLibrary' {
        BeforeEach {
            $script:Library = & $script:NewTestLibrary
        }
        It 'Should update the library name' {
            Set-IMLibrary -Id $script:Library.id -Name 'PSImmich-Test-Renamed' | Out-Null
            $Result = Get-IMLibrary -Id $script:Library.id
            $Result.name | Should -Be 'PSImmich-Test-Renamed'
        }
        It 'Should update the exclusion patterns' {
            Set-IMLibrary -Id $script:Library.id -ExclusionPatterns '*/cache/*' | Out-Null
            $Result = Get-IMLibrary -Id $script:Library.id
            $Result.exclusionPatterns | Should -Contain '*/cache/*'
        }
        It 'Should accept library IDs from the pipeline' {
            $script:Library | Set-IMLibrary -Name 'PSImmich-Test-Piped' | Out-Null
            $Result = Get-IMLibrary -Id $script:Library.id
            $Result.name | Should -Be 'PSImmich-Test-Piped'
        }
        It 'Should return a LibraryResponseDto object' {
            $Result = Set-IMLibrary -Id $script:Library.id -Name 'PSImmich-Test-Typed'
            $Result.PSObject.TypeNames | Should -Contain 'LibraryResponseDto'
        }
        It 'Should throw for a non-existent library ID' {
            { Set-IMLibrary -Id ([guid]::NewGuid().ToString()) -Name 'PSImmich-Test-Missing' } | Should -Throw
        }
    }

    Context 'Remove-IMLibrary' -Tag 'Remove-IMLibrary' {
        It 'Should remove a test library by ID' {
            $Library = & $script:NewTestLibrary
            Remove-IMLibrary -Id $Library.id -Confirm:$false
            $script:CreatedLibraryIds.Remove($Library.id) | Out-Null
            { Get-IMLibrary -Id $Library.id } | Should -Throw
        }
        It 'Should remove a test library from the pipeline' {
            $Library = & $script:NewTestLibrary
            $Library | Remove-IMLibrary -Confirm:$false
            $script:CreatedLibraryIds.Remove($Library.id) | Out-Null
            { Get-IMLibrary -Id $Library.id } | Should -Throw
        }
        It 'Should not remove the library when -WhatIf is used' {
            $Library = & $script:NewTestLibrary
            Remove-IMLibrary -Id $Library.id -WhatIf
            Get-IMLibrary -Id $Library.id | Should -HaveCount 1
        }
        It 'Should throw for a non-existent library ID' {
            { Remove-IMLibrary -Id ([guid]::NewGuid().ToString()) -Confirm:$false } | Should -Throw
        }
    }

    Context 'Test-IMLibrary' -Tag 'Test-IMLibrary' {
        BeforeAll {
            $script:Library = & $script:NewTestLibrary
        }
        It 'Should return a ValidateLibraryResponseDto object' {
            $Result = Test-IMLibrary -Id $script:Library.id
            $Result | Should -Not -BeNullOrEmpty
            $Result.PSObject.TypeNames | Should -Contain 'ValidateLibraryResponseDto'
        }
        It 'Should accept library IDs from the pipeline' {
            $Result = $script:Library.id | Test-IMLibrary
            $Result | Should -Not -BeNullOrEmpty
        }
    }
}
