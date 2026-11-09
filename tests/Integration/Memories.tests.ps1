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

# All Memory cmdlets are covered. New, Set and Remove only act on memories created by the test
# itself, and every created memory is removed in a finally block.
Describe 'Memories' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $Session = Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY -PassThru
        $AssetId = (Get-IMTopLargestAsset -Size 1 | Select-Object -First 1).id

        function New-TestMemory
        {
            $MemoryAt = (Get-Date).AddYears(-1).Date
            New-IMMemory -Year $MemoryAt.Year -MemoryAt $MemoryAt -AssetIds $AssetId
        }
    }

    Context 'Get-IMMemory' -Tag 'Get-IMMemory' {
        It -Name 'Should list memories without error' {
            { $Result = Get-IMMemory } | Should -Not -Throw
        }
        It -Name 'Should return MemoryResponseDto objects' {
            $Result = Get-IMMemory
            foreach ($Item in $Result)
            {
                $Item.PSObject.TypeNames | Should -Contain 'MemoryResponseDto'
                $Item.id | Should -Not -BeNullOrEmpty
            }
        }
        It -Name 'Should support Order parameter' {
            { $Result = Get-IMMemory -Order 'asc' } | Should -Not -Throw
            { $Result = Get-IMMemory -Order 'desc' } | Should -Not -Throw
            { $Result = Get-IMMemory -Order 'random' } | Should -Not -Throw
        }
        It -Name 'Should support NumberOfMemories parameter' {
            { $Result = Get-IMMemory -NumberOfMemories 5 } | Should -Not -Throw
            $Result = Get-IMMemory -NumberOfMemories 1
            $Result.Count | Should -BeLessOrEqual 1
        }
        It -Name 'Should support IsSaved parameter' {
            { $Result = Get-IMMemory -IsSaved:$true } | Should -Not -Throw
            { $Result = Get-IMMemory -IsSaved:$false } | Should -Not -Throw
        }
        It -Name 'Should support IsTrashed parameter' {
            { $Result = Get-IMMemory -IsTrashed:$true } | Should -Not -Throw
            { $Result = Get-IMMemory -IsTrashed:$false } | Should -Not -Throw
        }
        It -Name 'Should support Type parameter' {
            { $Result = Get-IMMemory -Type 'on_this_day' } | Should -Not -Throw
        }
        It -Name 'Should support For parameter for date filtering' {
            $TestDate = Get-Date -Format 'yyyy-MM-dd'
            { $Result = Get-IMMemory -For $TestDate } | Should -Not -Throw
        }
        It -Name 'Should support combined parameters' {
            { $Result = Get-IMMemory -Order 'desc' -NumberOfMemories 3 -IsSaved:$false } | Should -Not -Throw
        }
        It -Name 'Should return MemoryStatisticsResponseDto with -Statistics' {
            $Result = Get-IMMemory -Statistics
            $Result.PSObject.TypeNames | Should -Contain 'MemoryStatisticsResponseDto'
            $Result.total | Should -BeGreaterOrEqual 0
        }
        It -Name 'Should accept statistics with other list filters' {
            { $Result = Get-IMMemory -Statistics -Order 'desc' } | Should -Not -Throw
            { $Result = Get-IMMemory -Statistics -NumberOfMemories 5 } | Should -Not -Throw
        }
        It -Name 'Should return a memory by id' {
            $First = Get-IMMemory | Select-Object -First 1
            if (-not $First)
            {
                Set-ItResult -Skipped -Because 'no memories exist on the server'
                return
            }
            $Result = Get-IMMemory -Id $First.id
            $Result.id | Should -Be $First.id
        }
        It -Name 'Should accept memory ids from the pipeline' {
            $Memories = Get-IMMemory | Select-Object -First 1
            if (-not $Memories)
            {
                Set-ItResult -Skipped -Because 'no memories exist on the server'
                return
            }
            $Result = $Memories | Get-IMMemory
            $Result.id | Should -Be $Memories.id
        }
        It -Name 'Should throw for a memory that does not exist' {
            { Get-IMMemory -Id '00000000-0000-0000-0000-000000000000' } | Should -Throw
        }
        It -Name 'Should reject a malformed memory id' {
            { Get-IMMemory -Id 'not-a-guid' } | Should -Throw
        }
        It -Name 'Should reject an invalid Order' {
            { Get-IMMemory -Order 'sideways' } | Should -Throw
        }
        It -Name 'Should reject an invalid Type' {
            { Get-IMMemory -Type 'yesterday' } | Should -Throw
        }
        It -Name 'Should reject -Statistics combined with -Id' {
            { Get-IMMemory -Id '00000000-0000-0000-0000-000000000000' -Statistics } | Should -Throw
        }
        It -Name 'Should accept an explicit session' {
            { Get-IMMemory -Session $Session -NumberOfMemories 1 } | Should -Not -Throw
        }
    }

    Context 'New-IMMemory' -Tag 'New-IMMemory' {
        It -Name 'Should create a memory and remove it again' {
            $Created = $null
            try
            {
                $Created = New-TestMemory
                $Created.PSObject.TypeNames | Should -Contain 'MemoryResponseDto'
                $Created.id | Should -Not -BeNullOrEmpty
                $Created.type | Should -Be 'on_this_day'
            }
            finally
            {
                if ($Created)
                {
                    Remove-IMMemory -Id $Created.id -Confirm:$false
                }
            }
        }
        It -Name 'Should contain the requested asset' {
            $Created = $null
            try
            {
                $Created = New-TestMemory
                $Fetched = Get-IMMemory -Id $Created.id
                $Fetched.assets.id | Should -Contain $AssetId
            }
            finally
            {
                if ($Created)
                {
                    Remove-IMMemory -Id $Created.id -Confirm:$false
                }
            }
        }
        It -Name 'Should create a memory with an explicit SeenAt' {
            $Created = $null
            try
            {
                $MemoryAt = (Get-Date).AddYears(-2).Date
                $Created = New-IMMemory -Year $MemoryAt.Year -MemoryAt $MemoryAt -AssetIds $AssetId -SeenAt (Get-Date)
                $Created.id | Should -Not -BeNullOrEmpty
            }
            finally
            {
                if ($Created)
                {
                    Remove-IMMemory -Id $Created.id -Confirm:$false
                }
            }
        }
        It -Name 'Should reject a Year below 1' {
            { New-IMMemory -Year 0 -MemoryAt (Get-Date) -AssetIds $AssetId } | Should -Throw
        }
        It -Name 'Should reject a malformed asset id' {
            { New-IMMemory -Year 2020 -MemoryAt (Get-Date) -AssetIds 'not-a-guid' } | Should -Throw
        }
        It -Name 'Should reject an invalid Type' {
            { New-IMMemory -Year 2020 -MemoryAt (Get-Date) -AssetIds $AssetId -Type 'yesterday' } | Should -Throw
        }
    }

    Context 'Set-IMMemory' -Tag 'Set-IMMemory' {
        It -Name 'Should update IsSaved on a memory the test created' {
            $Created = $null
            try
            {
                $Created = New-TestMemory
                Set-IMMemory -Id $Created.id -IsSaved $true -Confirm:$false
                $Fetched = Get-IMMemory -Id $Created.id
                $Fetched.isSaved | Should -BeTrue
            }
            finally
            {
                if ($Created)
                {
                    Remove-IMMemory -Id $Created.id -Confirm:$false
                }
            }
        }
        It -Name 'Should update MemoryAt and SeenAt' {
            $Created = $null
            try
            {
                $Created = New-TestMemory
                $NewMemoryAt = (Get-Date).AddYears(-3).Date
                Set-IMMemory -Id $Created.id -MemoryAt $NewMemoryAt -SeenAt (Get-Date) -Confirm:$false
                $Fetched = Get-IMMemory -Id $Created.id
                $Fetched.memoryAt.ToLocalTime().Date | Should -Be $NewMemoryAt
                $Fetched.seenAt | Should -Not -BeNullOrEmpty
            }
            finally
            {
                if ($Created)
                {
                    Remove-IMMemory -Id $Created.id -Confirm:$false
                }
            }
        }
        It -Name 'Should accept memory ids from the pipeline' {
            $Created = $null
            try
            {
                $Created = New-TestMemory
                $Created | Set-IMMemory -IsSaved $true -Confirm:$false
                (Get-IMMemory -Id $Created.id).isSaved | Should -BeTrue
            }
            finally
            {
                if ($Created)
                {
                    Remove-IMMemory -Id $Created.id -Confirm:$false
                }
            }
        }
        It -Name 'Should not change anything with -WhatIf' {
            $Created = $null
            try
            {
                $Created = New-TestMemory
                Set-IMMemory -Id $Created.id -IsSaved $true -WhatIf
                (Get-IMMemory -Id $Created.id).isSaved | Should -BeFalse
            }
            finally
            {
                if ($Created)
                {
                    Remove-IMMemory -Id $Created.id -Confirm:$false
                }
            }
        }
        It -Name 'Should throw for a memory that does not exist' {
            { Set-IMMemory -Id '00000000-0000-0000-0000-000000000000' -IsSaved $true -Confirm:$false } | Should -Throw
        }
    }

    Context 'Remove-IMMemory' -Tag 'Remove-IMMemory' {
        It -Name 'Should remove a memory the test created' {
            $Created = $null
            try
            {
                $Created = New-TestMemory
                Remove-IMMemory -Id $Created.id -Confirm:$false
                { Get-IMMemory -Id $Created.id } | Should -Throw
            }
            finally
            {
                if ($Created)
                {
                    try { Remove-IMMemory -Id $Created.id -Confirm:$false } catch { }
                }
            }
        }
        It -Name 'Should remove a memory from the pipeline' {
            $Created = $null
            try
            {
                $Created = New-TestMemory
                $Created | Remove-IMMemory -Confirm:$false
                { Get-IMMemory -Id $Created.id } | Should -Throw
            }
            finally
            {
                if ($Created)
                {
                    try { Remove-IMMemory -Id $Created.id -Confirm:$false } catch { }
                }
            }
        }
        It -Name 'Should not remove a memory with -WhatIf' {
            $Created = $null
            try
            {
                $Created = New-TestMemory
                Remove-IMMemory -Id $Created.id -WhatIf
                { Get-IMMemory -Id $Created.id } | Should -Not -Throw
            }
            finally
            {
                if ($Created)
                {
                    Remove-IMMemory -Id $Created.id -Confirm:$false
                }
            }
        }
        It -Name 'Should throw for a memory that does not exist' {
            { Remove-IMMemory -Id '00000000-0000-0000-0000-000000000000' -Confirm:$false } | Should -Throw
        }
    }
}
