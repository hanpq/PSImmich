BeforeAll {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $conversionScript = Join-Path $projectRoot 'scripts\ConvertTo-SourceCoverage.ps1'
    Import-Module (Join-Path $projectRoot 'output\RequiredModules\ModuleBuilder\3.1.8\ModuleBuilder.psd1') -Force
}

Describe 'Built module coverage source mapping' {
    BeforeEach {
        $fixture = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $source = Join-Path $fixture 'source'
        New-Item -ItemType Directory -Path (Join-Path $source 'Public'), (Join-Path $source 'Private') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $source 'Public\First.ps1') -Value @(
            'function Test-First {', "'hit'", "'miss'", '}'
        )
        Set-Content -LiteralPath (Join-Path $source 'Private\Second.ps1') -Value @(
            'function Test-Second {', "'hit'", '}'
        )
        $builtModule = Join-Path $fixture 'ExampleModule.psm1'
        Set-Content -LiteralPath $builtModule -Value @(
            "#Region './prefix.ps1' -1", '', "Write-Output 'init'", "#EndRegion './prefix.ps1' 2",
            "#Region '.\Public\First.ps1' -1", '', 'function Test-First {', "'hit'", "'miss'", '}', "#EndRegion '.\Public\First.ps1' 5",
            "#Region './Private/Second.ps1' -1", '', 'function Test-Second {', "'hit'", '}', "#EndRegion './Private/Second.ps1' 4"
        )
        $reportPath = Join-Path $fixture 'JaCoCo_coverage.xml'
        Set-Content -LiteralPath $reportPath -Value @'
<report name="built">
  <sessioninfo id="test-session" start="123" dump="456"/>
  <package name="output/ExampleModule">
    <sourcefile name="ExampleModule.psm1">
      <line nr="3" mi="0" ci="1" mb="0" cb="0"/>
      <line nr="8" mi="1" ci="2" mb="0" cb="0"/>
      <line nr="9" mi="1" ci="0" mb="0" cb="0"/>
      <line nr="15" mi="0" ci="1" mb="0" cb="0"/>
    </sourcefile>
  </package>
</report>
'@
    }

    It 'preserves hit counts at the original tracked source lines with Codecov-compatible paths' {
        & $conversionScript -ReportPath $reportPath -BuiltModulePath $builtModule -SourceDirectory $source

        [xml]$report = Get-Content -LiteralPath $reportPath -Raw
        $report.report.sessioninfo.id | Should -Be 'test-session'
        @($report.report.package.name) | Should -Be @('source/Private', 'source/Public')
        $public = $report.SelectSingleNode('/report/package[@name="source/Public"]/sourcefile')
        $public.name | Should -Be 'First.ps1'
        @($public.line.nr) | Should -Be @('2', '3')
        $public.line[0].ci | Should -Be '2'
        $public.line[0].mi | Should -Be '1'
        $public.line[1].ci | Should -Be '0'
        $private = $report.SelectSingleNode('/report/package[@name="source/Private"]/sourcefile')
        $private.name | Should -Be 'Second.ps1'
        $private.line.nr | Should -Be '2'
        $private.line.ci | Should -Be '1'
        $report.OuterXml | Should -Not -Match 'prefix.ps1|ExampleModule.psm1|output/'
    }

    It 'recomputes instruction and line totals after excluding non-function source files' {
        & $conversionScript -ReportPath $reportPath -BuiltModulePath $builtModule -SourceDirectory $source

        [xml]$report = Get-Content -LiteralPath $reportPath -Raw
        $instructions = $report.SelectSingleNode('/report/counter[@type="INSTRUCTION"]')
        $instructions.covered | Should -Be '3'
        $instructions.missed | Should -Be '2'
        $lines = $report.SelectSingleNode('/report/counter[@type="LINE"]')
        $lines.covered | Should -Be '2'
        $lines.missed | Should -Be '1'
        foreach ($scope in $report.SelectNodes('/report/package | /report/package/sourcefile'))
        {
            @($scope.counter.type) | Should -Be @('INSTRUCTION', 'BRANCH', 'LINE')
        }
    }

    It 'fails rather than publishing coverage mapped to nonexistent source files' {
        Remove-Item -LiteralPath (Join-Path $source 'Public\First.ps1')
        $original = Get-Content -LiteralPath $reportPath -Raw

        { & $conversionScript -ReportPath $reportPath -BuiltModulePath $builtModule -SourceDirectory $source } |
            Should -Throw '*Invalid source coverage mapping*'

        Get-Content -LiteralPath $reportPath -Raw | Should -Be $original
    }

    It 'rejects a report for a different built module' {
        (Get-Content -LiteralPath $reportPath -Raw).Replace('ExampleModule.psm1', 'OtherModule.psm1') |
            Set-Content -LiteralPath $reportPath

        { & $conversionScript -ReportPath $reportPath -BuiltModulePath $builtModule -SourceDirectory $source } |
            Should -Throw '*Expected a JaCoCo coverage report for exactly the built module*'
    }

    It 'rejects coverage with no function source lines' {
        Set-Content -LiteralPath $reportPath -Value '<report><package name="output"><sourcefile name="ExampleModule.psm1"><line nr="3" mi="0" ci="1" mb="0" cb="0"/></sourcefile></package></report>'

        { & $conversionScript -ReportPath $reportPath -BuiltModulePath $builtModule -SourceDirectory $source } |
            Should -Throw '*No coverage lines mapped*'
    }
}
