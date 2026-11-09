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

# All Map cmdlets are covered; all tests are read-only.
Describe 'Map' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $Session = Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY -PassThru
    }

    Context 'Convert-IMCoordinatesToLocation' -Tag 'Convert-IMCoordinatesToLocation' {
        It 'Should return location of Kensington' {
            $Result = Convert-IMCoordinatesToLocation -Latitude 51.496637 -Longitude -0.176370
            $Result.country | Should -Be 'United Kingdom'
            $Result.state | Should -Be 'England'
            $Result.city | Should -Be 'Kensington'
        }
        It 'Should return a MapReverseGeocodeResponseDto' {
            $Result = Convert-IMCoordinatesToLocation -Latitude 37.7749 -Longitude -122.4194
            $Result.PSObject.TypeNames | Should -Contain 'MapReverseGeocodeResponseDto'
        }
        It 'Should return location of San Francisco' {
            $Result = Convert-IMCoordinatesToLocation -Latitude 37.7749 -Longitude -122.4194
            $Result.country | Should -Be 'United States'
            $Result.state | Should -Be 'California'
            $Result.city | Should -Be 'San Francisco'
        }
        It 'Should accept an explicit session' {
            { Convert-IMCoordinatesToLocation -Latitude 37.7749 -Longitude -122.4194 -Session $Session } | Should -Not -Throw
        }
    }

    Context 'Get-IMMapMarker' -Tag 'Get-IMMapMarker' {
        It 'Should return markers without error' {
            { Get-IMMapMarker } | Should -Not -Throw
        }
        It 'Should return MapMarkerResponseDto objects with valid coordinates' {
            $Result = Get-IMMapMarker
            foreach ($Item in $Result)
            {
                $Item.PSObject.TypeNames | Should -Contain 'MapMarkerResponseDto'
                $Item.lat | Should -BeGreaterOrEqual -90
                $Item.lat | Should -BeLessOrEqual 90
                $Item.lon | Should -BeGreaterOrEqual -180
                $Item.lon | Should -BeLessOrEqual 180
            }
        }
        It 'Should return no markers for CreatedAfter in the future' {
            Get-IMMapMarker -CreatedAfter (Get-Date).AddYears(10) | Should -BeNullOrEmpty
        }
        It 'Should return no markers for CreatedBefore before any asset' {
            Get-IMMapMarker -CreatedBefore ([datetime]'1800-01-01') | Should -BeNullOrEmpty
        }
        It 'Should return no more favorite markers than all markers' {
            $All = Get-IMMapMarker
            $Favorites = Get-IMMapMarker -IsFavorite $true
            $All.Count | Should -BeGreaterOrEqual $Favorites.Count
        }
        It 'Should accept <Name> = <Value>' -ForEach @(
            @{ Name = 'IsArchived'; Value = $false }
            @{ Name = 'IsArchived'; Value = $true }
            @{ Name = 'WithPartners'; Value = $true }
            @{ Name = 'WithSharedAlbums'; Value = $true }
        ) {
            $Params = @{ $Name = $Value }
            { Get-IMMapMarker @Params } | Should -Not -Throw
        }
        It 'Should accept an explicit session' {
            { Get-IMMapMarker -Session $Session } | Should -Not -Throw
        }
    }
}
