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

# The only Timeline cmdlet is covered; all tests are read-only.
Describe 'Timeline' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $Session = Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY -PassThru
    }

    Context 'Get-IMTimeBucket' -Tag 'Get-IMTimeBucket' {
        It 'Should return time buckets' {
            $Result = Get-IMTimeBucket
            $Result.Count | Should -BeGreaterThan 0
        }
        It 'Should return bucket objects with timeBucket and count' {
            $Result = Get-IMTimeBucket
            foreach ($Item in $Result)
            {
                $Item.timeBucket | Should -Not -BeNullOrEmpty
                $Item.count | Should -BeGreaterThan 0
            }
        }
        It 'Should return assets for a known time bucket' {
            $Result = Get-IMTimeBucket -timeBucket '2024-03-01 00:00:00'
            $Result.id | Should -HaveCount 12
        }
        It 'Should return assets for a time bucket returned by the list' {
            $Bucket = (Get-IMTimeBucket | Select-Object -First 1).timeBucket
            $Result = Get-IMTimeBucket -TimeBucket $Bucket
            $Result.id.Count | Should -BeGreaterThan 0
        }
        It 'Should return the same number of buckets for asc and desc order' {
            $Asc = Get-IMTimeBucket -Order asc
            $Desc = Get-IMTimeBucket -Order desc
            $Asc.Count | Should -Be $Desc.Count
        }
        It 'Should accept <Name> = <Value>' -ForEach @(
            @{ Name = 'OrderBy'; Value = 'takenAt' }
            @{ Name = 'OrderBy'; Value = 'createdAt' }
            @{ Name = 'Visibility'; Value = 'timeline' }
            @{ Name = 'IsFavorite'; Value = $false }
            @{ Name = 'IsTrashed'; Value = $false }
            @{ Name = 'WithCoordinates'; Value = $true }
            @{ Name = 'WithPartners'; Value = $false }
            @{ Name = 'WithStacked'; Value = $true }
        ) {
            $Params = @{ $Name = $Value }
            { Get-IMTimeBucket @Params } | Should -Not -Throw
        }
        It 'Should accept an explicit session' {
            { Get-IMTimeBucket -Session $Session } | Should -Not -Throw
        }
        It 'Should reject an invalid Order' {
            { Get-IMTimeBucket -Order 'sideways' } | Should -Throw
        }
        It 'Should reject an invalid Visibility' {
            { Get-IMTimeBucket -Visibility 'public' } | Should -Throw
        }
        It 'Should reject a malformed AlbumId' {
            { Get-IMTimeBucket -AlbumId 'not-a-guid' } | Should -Throw
        }
    }
}
