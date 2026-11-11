BeforeAll {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $CoverageScript = Join-Path $ProjectRoot 'tools\Get-ImmichApiCoverage.ps1'
}

Describe 'Immich API reachability coverage' -Tag 'ApiCoverage' {
    BeforeEach {
        $Fixture = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $Source = Join-Path $Fixture 'source'
        $Tests = Join-Path $Fixture 'tests'
        New-Item -ItemType Directory -Force -Path (Join-Path $Source 'private\api'), (Join-Path $Source 'public'), (Join-Path $Tests 'Private') | Out-Null
        $SpecPath = Join-Path $Fixture 'spec.json'
        $ExclusionsPath = Join-Path $Fixture 'exclusions.json'
        @'
{
  "paths": {
    "/tested": { "get": { "operationId": "tested" } },
    "/reachable": { "get": { "operationId": "reachable" } },
    "/unreachable": { "get": { "operationId": "unreachable" } },
    "/excluded": { "get": { "operationId": "excluded" } }
  }
}
'@ | Set-Content -LiteralPath $SpecPath
        '{"ExcludedPaths":[{"Path":"/excluded","Method":"GET","Reason":"Fixture exclusion"}]}' |
            Set-Content -LiteralPath $ExclusionsPath
        @(
            'Invoke-ImmichApiTested'
            'Invoke-ImmichApiReachable'
        ) | Set-Content -LiteralPath (Join-Path $Source 'public\Calls.ps1')
        'Invoke-ImmichApiUnreachable' | Set-Content -LiteralPath (Join-Path $Source 'private\api\Generated.ps1')
        'Invoke-ImmichApiTested' | Set-Content -LiteralPath (Join-Path $Tests 'Private\Manual.Tests.ps1')
        @(
            'Invoke-ImmichApiReachable'
            'Invoke-ImmichApiUnreachable'
        ) | Set-Content -LiteralPath (Join-Path $Tests 'Private\ImmichApi.Generated.Tests.ps1')
    }

    It 'does not treat generated route tests as public reachability or manual test evidence' {
        $Report = & $CoverageScript -SpecPath $SpecPath -ExclusionsPath $ExclusionsPath -SourcePath $Source -TestPath $Tests -PassThru
        ($Report | Where-Object Path -eq '/tested').Status | Should -Be 'Tested'
        ($Report | Where-Object Path -eq '/reachable').Status | Should -Be 'Reachable'
        ($Report | Where-Object Path -eq '/unreachable').Status | Should -Be 'Unreachable'
        ($Report | Where-Object Path -eq '/excluded').Status | Should -Be 'Excluded'
    }
}
