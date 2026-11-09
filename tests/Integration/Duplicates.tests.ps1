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

# Intentionally excluded: Remove-IMDuplicate and Resolve-IMDuplicate. Both are destructive
# (they delete or merge assets on the shared live server), so they are not exercised here.
Describe 'Duplicates' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $Session = Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY -PassThru
    }

    Context 'Get-IMDuplicate' -Tag 'Get-IMDuplicate' {
        It 'Should not throw' {
            { Get-IMDuplicate } | Should -Not -Throw
        }
        It 'Should return DuplicateResponseDto objects' {
            $Result = Get-IMDuplicate
            foreach ($Item in $Result)
            {
                $Item.PSObject.TypeNames | Should -Contain 'DuplicateResponseDto'
            }
        }
        It 'Should return groups with a duplicateId' {
            $Result = Get-IMDuplicate
            foreach ($Group in $Result)
            {
                $Group.duplicateId | Should -Not -BeNullOrEmpty
            }
        }
        It 'Should return groups containing at least two assets' {
            $Result = Get-IMDuplicate
            foreach ($Group in $Result)
            {
                $Group.assets.Count | Should -BeGreaterThan 1
            }
        }
        It 'Should only suggest keep ids that belong to the group' {
            $Result = Get-IMDuplicate
            foreach ($Group in $Result)
            {
                $AssetIds = $Group.assets.id
                foreach ($KeepId in $Group.suggestedKeepAssetIds)
                {
                    $AssetIds | Should -Contain $KeepId
                }
            }
        }
        It 'Should accept an explicit session' {
            { Get-IMDuplicate -Session $Session } | Should -Not -Throw
        }
    }
}
