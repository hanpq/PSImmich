BeforeAll {
    . (Join-Path $PSScriptRoot '..\Integration\Support\Wait-TestAssetTagState.ps1')
    function Get-IMAsset { param($Id) }
}

Describe 'Tag integration state polling' -Tag 'TagIntegration' {
    BeforeEach {
        $script:Reads = 0
        Mock Start-Sleep {}
    }

    It 'waits for the specific tag to appear' {
        Mock Get-IMAsset {
            $script:Reads++
            if ($script:Reads -eq 1) { return [pscustomobject]@{ tags = @() } }
            [pscustomobject]@{ tags = @([pscustomobject]@{ id = 'wanted' }) }
        }
        { Wait-TestAssetTagState -AssetId 'asset' -TagId 'wanted' -Present $true } | Should -Not -Throw
        Should -Invoke Get-IMAsset -Times 2 -Exactly -ParameterFilter { $Id -eq 'asset' }
        Should -Invoke Start-Sleep -Times 1 -Exactly
    }

    It 'waits for the specific tag to disappear while allowing other tags' {
        Mock Get-IMAsset {
            $script:Reads++
            if ($script:Reads -eq 1) { return [pscustomobject]@{ tags = @([pscustomobject]@{ id = 'wanted' }) } }
            [pscustomobject]@{ tags = @([pscustomobject]@{ id = 'other' }) }
        }
        { Wait-TestAssetTagState -AssetId 'asset' -TagId 'wanted' -Present $false } | Should -Not -Throw
        Should -Invoke Get-IMAsset -Times 2 -Exactly
    }

    It 'fails with observed tags when the desired state does not arrive' {
        Mock Get-IMAsset { [pscustomobject]@{ tags = @([pscustomobject]@{ id = 'wanted' }) } }
        { Wait-TestAssetTagState -AssetId 'asset' -TagId 'wanted' -Present $false -TimeoutSeconds 0 } |
            Should -Throw "*tag 'wanted' to be absent on asset 'asset'*Observed tags: wanted*"
        Should -Invoke Get-IMAsset -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0
    }

    It 'propagates asset retrieval errors without retrying' {
        Mock Get-IMAsset { throw 'read failed' }
        { Wait-TestAssetTagState -AssetId 'asset' -TagId 'wanted' -Present $true } | Should -Throw '*read failed*'
        Should -Invoke Get-IMAsset -Times 1 -Exactly
    }
}

Describe 'Plugin integration trigger contract' -Tag 'PluginIntegration' {
    It 'accepts exactly the workflow trigger enum from the 3.4.0 spec' {
        $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
        $Spec = Get-Content -LiteralPath (Join-Path $ProjectRoot 'api\api.3.4.0.json') -Raw | ConvertFrom-Json
        $PluginTests = Get-Content -LiteralPath (Join-Path $ProjectRoot 'tests\Integration\Plugin.tests.ps1') -Raw
        $Match = [regex]::Match($PluginTests, '\$Template\.trigger\s*\|\s*Should\s+-BeIn\s+@\(([^)]*)\)')
        $Match.Success | Should -BeTrue
        $Actual = @([regex]::Matches($Match.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
        $Expected = @($Spec.components.schemas.WorkflowTrigger.enum)
        $Actual.Count | Should -Be $Expected.Count
        foreach ($Trigger in $Expected)
        {
            $Actual | Should -Contain $Trigger
        }
    }
}
