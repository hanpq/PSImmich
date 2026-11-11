BeforeAll {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $Workflow = Get-Content -LiteralPath (Join-Path $ProjectRoot '.github\workflows\integration.yml') -Raw
    $CI = Get-Content -LiteralPath (Join-Path $ProjectRoot '.github\workflows\ci.yml') -Raw
    $SummaryText = [regex]::Match($Workflow, '(?s)- name: Summarize integration results.*?run: \|\r?\n(?<code>.*?)(?=      - name: Upload integration report)').Groups['code'].Value
    $Summary = [scriptblock]::Create(($SummaryText -replace '(?m)^          ', ''))
}

Describe 'Manual integration workflow contract' -Tag 'IntegrationWorkflow' {
    It 'keeps live integration out of automatic CI and release publishing' {
        $CI | Should -Not -Match '(?im)^\s+integration:\s*$'
        $CI | Should -Not -Match 'TestSuite Integration|PSIMMICHAPIKEY'
        $Release = Get-Content -LiteralPath (Join-Path $ProjectRoot '.github\workflows\release.yml') -Raw
        $Release | Should -Not -Match 'TestSuite Integration|PSIMMICHAPIKEY'
        $CI | Should -Match 'TestSuite Module'
        $CI | Should -Match 'TestSuite Infrastructure'
    }

    It 'dispatches manually from main with minimal permissions and a shared queue' {
        $Workflow | Should -Match '(?m)^  workflow_dispatch:\s*$'
        $Workflow | Should -Not -Match '(?m)^  (push|pull_request|schedule|workflow_call):'
        $Workflow | Should -Match '(?m)^  contents: read\s*$'
        $Workflow | Should -Match '(?m)^  group: immich-demo-integration\s*$'
        $Workflow | Should -Match '(?m)^  cancel-in-progress: false\s*$'
        $Workflow | Should -Match '(?m)^  queue: max\s*$'
        $Workflow | Should -Match "(?s)Require trusted main.*?GITHUB_REF -cne 'refs/heads/main'.*?actions/checkout@v6.*?Record test target"
        $Workflow | Should -Match 'persist-credentials: false'
    }

    It 'records the exact commit and server version before running the live suite' {
        $Workflow | Should -Match '(?s)git rev-parse HEAD.*?\$env:GITHUB_SHA.*?/api/server/version.*?Run integration suite.*?TestSuite Integration'
        foreach ($Name in 'PSIMMICHURI', 'PSIMMICHAPIKEY', 'PSIMMICHUSER', 'PSIMMICHPASSWORD') {
            $Workflow | Should -Match ([regex]::Escape("secrets.$Name"))
        }
        $Workflow | Should -Match '(?s)Summarize integration results\s+if: always\(\)'
        $Workflow | Should -Match '(?s)Upload integration report\s+if: always\(\)'
    }
}

Describe 'Integration workflow summary' -Tag 'IntegrationWorkflow' {
    BeforeEach {
        $Fixture = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $Fixture | Out-Null
        Push-Location $Fixture
        $OldEnvironment = @{}
        foreach ($Name in 'GITHUB_STEP_SUMMARY', 'TEST_COMMIT', 'SERVER_VERSION', 'TEST_OUTCOME') {
            $OldEnvironment[$Name] = [Environment]::GetEnvironmentVariable($Name)
        }
        $env:GITHUB_STEP_SUMMARY = Join-Path $Fixture 'summary.md'
        $env:TEST_COMMIT = 'abcdef'
        $env:SERVER_VERSION = '3.4.0'
        $env:TEST_OUTCOME = 'failure'
    }
    AfterEach {
        Pop-Location
        foreach ($Name in $OldEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($Name, $OldEnvironment[$Name])
        }
    }

    It 'records results and skipped test names from the NUnit report' {
        New-Item -ItemType Directory -Force -Path 'output\testResults' | Out-Null
        @'
<test-results total="3" failures="1" errors="0" skipped="1">
  <test-case name="Tag.test" result="Skipped" />
</test-results>
'@ | Set-Content -LiteralPath 'output\testResults\PSImmich.Tests.xml'
        & $Summary
        $Text = Get-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Raw
        $Text | Should -Match 'Commit: abcdef'
        $Text | Should -Match 'Server version: 3\.4\.0'
        $Text | Should -Match 'Test step: failure'
        $Text | Should -Match 'Total: 3; failures: 1; errors: 0; skipped: 1'
        $Text | Should -Match 'Tag\.test'
    }

    It 'reports when no test report was produced' {
        & $Summary
        Get-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Raw | Should -Match 'No integration test report was produced'
    }
}
