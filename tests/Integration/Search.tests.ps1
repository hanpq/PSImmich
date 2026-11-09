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

# All Search cmdlets are covered; all tests are read-only.
Describe 'Search' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $Session = Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY -PassThru
    }

    Context 'Find-IMExploreData' -Tag 'Find-IMExploreData' {
        It 'Should return explore data without error' {
            { Find-IMExploreData } | Should -Not -Throw
        }
        It 'Should return SearchExploreResponseDto objects' {
            $Result = Find-IMExploreData
            foreach ($Item in $Result)
            {
                $Item.PSObject.TypeNames | Should -Contain 'SearchExploreResponseDto'
            }
        }
        It 'Should accept an explicit session' {
            { Find-IMExploreData -Session $Session } | Should -Not -Throw
        }
    }

    Context 'Find-IMPerson' -Tag 'Find-IMPerson' {
        It 'Should return PersonResponseDto objects for a name search' {
            $Result = Find-IMPerson -Name 'a'
            foreach ($Item in $Result)
            {
                $Item.PSObject.TypeNames | Should -Contain 'PersonResponseDto'
            }
        }
        It 'Should return nothing for a name that does not exist' {
            $Name = "NoSuchPerson-$($env:GITHUB_RUN_ID)-$(Get-Random)"
            Find-IMPerson -Name $Name | Should -BeNullOrEmpty
        }
        It 'Should accept -WithHidden' {
            { Find-IMPerson -Name 'a' -WithHidden $true } | Should -Not -Throw
        }
        It 'Should accept an explicit session' {
            { Find-IMPerson -Name 'a' -Session $Session } | Should -Not -Throw
        }
    }

    Context 'Find-IMPlace' -Tag 'Find-IMPlace' {
        It 'Should return PlacesResponseDto objects for a place name' {
            $Result = Find-IMPlace -Name 'London'
            $Result | Should -Not -BeNullOrEmpty
            foreach ($Item in $Result)
            {
                $Item.PSObject.TypeNames | Should -Contain 'PlacesResponseDto'
            }
        }
        It 'Should return nothing for a place that does not exist' {
            Find-IMPlace -Name "NoSuchPlace-$($env:GITHUB_RUN_ID)-$(Get-Random)" | Should -BeNullOrEmpty
        }
        It 'Should accept an explicit session' {
            { Find-IMPlace -Name 'London' -Session $Session } | Should -Not -Throw
        }
    }

    Context 'Get-IMTopLargestAsset' -Tag 'Get-IMTopLargestAsset' {
        It 'Should return at most the requested number of assets' {
            $Result = Get-IMTopLargestAsset -Size 5
            $Result.Count | Should -BeLessOrEqual 5
        }
        It 'Should default to at most 100 assets' {
            $Result = Get-IMTopLargestAsset
            $Result.Count | Should -BeLessOrEqual 100
        }
        It 'Should return AssetResponseDto objects' {
            $Result = Get-IMTopLargestAsset -Size 3
            foreach ($Item in $Result)
            {
                $Item.PSObject.TypeNames | Should -Contain 'AssetResponseDto'
            }
        }
        It 'Should reject Size <Size>' -ForEach @(@{ Size = 0 }, @{ Size = 1001 }) {
            { Get-IMTopLargestAsset -Size $Size } | Should -Throw
        }
        It 'Should accept an explicit session' {
            { Get-IMTopLargestAsset -Size 1 -Session $Session } | Should -Not -Throw
        }
    }

    Context 'Search-IMAsset' -Tag 'Search-IMAsset' {
        It 'Should return multiple assets with correct type' {
            $Result = Search-IMAsset
            $Result | Measure-Object | Select-Object -ExpandProperty count | Should -BeGreaterThan 1
            $Result[0].PSObject.TypeNames | Should -Contain 'AssetResponseDto'
        }
        It 'Should find asset by name' {
            $Result = Search-IMAsset -OriginalFileName 'evgeni-evgeniev-ggVH1hoQAac-unsplash.jpg'
            $Result | Should -HaveCount 1
        }
        It 'Should not match partial file names (exact match filter)' {
            $Result = Search-IMAsset -OriginalFileName 'unsp'
            $Result | Should -HaveCount 0
        }
        It 'Should find all assets by paging' {
            $All = Search-IMAsset -Type IMAGE
            $Paged = Search-IMAsset -Type IMAGE -Size 5
            $Paged | Should -HaveCount $All.Count
        }
        It 'Should find road assets with smart search' {
            $Result = Search-IMAsset -Smart -Query 'Road'
            $Result.Count | Should -BeGreaterThan 0
        }
        It 'Should page smart search results without losing assets' {
            $All = Search-IMAsset -Smart -Query 'Road'
            $Paged = Search-IMAsset -Smart -Query 'Road' -Size 2
            $Paged | Should -HaveCount $All.Count
        }
        It 'Should translate PascalCase boolean parameters to API filters' {
            { Search-IMAsset -IsFavorite:$false -IsEncoded:$true -Type 'IMAGE' } | Should -Not -Throw
        }
        It 'Should return the expected asset for a smart search' {
            $Result = Search-IMAsset -Smart -Query 'Road'
            $Result[0].OriginalFileName | Should -Be 'evgeni-evgeniev-ggVH1hoQAac-unsplash.jpg'
        }
        It 'Should return only favorites when IsFavorite is true' {
            $Result = Search-IMAsset -IsFavorite $true
            foreach ($Item in $Result)
            {
                $Item.isFavorite | Should -BeTrue
            }
        }
        It 'Should return the same count for ascending and descending order' {
            $Asc = Search-IMAsset -Type IMAGE -Order asc
            $Desc = Search-IMAsset -Type IMAGE -Order desc
            $Asc | Should -HaveCount $Desc.Count
        }
        It 'Should return nothing when CreatedAfter is in the future' {
            Search-IMAsset -CreatedAfter (Get-Date).AddYears(10) | Should -BeNullOrEmpty
        }
        It 'Should return nothing when TakenBefore is before any asset' {
            Search-IMAsset -TakenBefore ([datetime]'1800-01-01') | Should -BeNullOrEmpty
        }
        It 'Should accept -IsNotInAlbum' {
            { Search-IMAsset -IsNotInAlbum -Type IMAGE } | Should -Not -Throw
        }
        It 'Should accept an explicit session' {
            { Search-IMAsset -Session $Session -Type IMAGE -Size 1 } | Should -Not -Throw
        }
        It 'Should reject -Query without -Smart' {
            { Search-IMAsset -Query 'Road' } | Should -Throw
        }
        It 'Should reject -Order with -Smart' {
            { Search-IMAsset -Smart -Query 'Road' -Order 'asc' } | Should -Throw
        }
        It 'Should reject an invalid Type' {
            { Search-IMAsset -Type 'DOCUMENT' } | Should -Throw
        }
        It 'Should reject a Rating outside -1 to 5' {
            { Search-IMAsset -Rating 6 } | Should -Throw
        }
    }
}
