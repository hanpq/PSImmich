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

# Intentionally excluded: New-IMFace, Set-IMFace and Remove-IMFace. They create, edit or delete
# face data on assets in the shared live server, so only the read-only Get-IMFace is tested.
Describe 'Face' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $Session = Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY -PassThru
    }

    Context 'Get-IMFace' -Tag 'Get-IMFace' {
        It 'Should return faces' {
            $Result = Get-IMFace -Id 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
            $Result | Should -HaveCount 5
        }
        It 'Should return AssetFaceResponseDto objects with bounding boxes' {
            $Result = Get-IMFace -Id 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
            foreach ($Face in $Result)
            {
                $Face.PSObject.TypeNames | Should -Contain 'AssetFaceResponseDto'
                $Face.id | Should -Not -BeNullOrEmpty
                $Face.boundingBoxX2 | Should -BeGreaterOrEqual $Face.boundingBoxX1
                $Face.boundingBoxY2 | Should -BeGreaterOrEqual $Face.boundingBoxY1
            }
        }
        It 'Should return faces for multiple asset ids' {
            $AssetId = 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
            $Single = Get-IMFace -Id $AssetId
            $Multiple = Get-IMFace -Id @($AssetId, $AssetId)
            $Multiple | Should -HaveCount (2 * $Single.Count)
        }
        It 'Should accept asset ids from the pipeline' {
            $Assets = Get-IMTopLargestAsset -Size 3
            { $Assets | Get-IMFace } | Should -Not -Throw
        }
        It 'Should accept an explicit session' {
            { Get-IMFace -Id 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c' -Session $Session } | Should -Not -Throw
        }
        It 'Should throw for an asset that does not exist' {
            { Get-IMFace -Id '00000000-0000-0000-0000-000000000000' } | Should -Throw
        }
        It 'Should reject a malformed asset id' {
            { Get-IMFace -Id 'not-a-guid' } | Should -Throw
        }
    }
}
