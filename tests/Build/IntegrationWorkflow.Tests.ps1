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

    It 'uploads only the reduced JSON report, never the raw NUnit report' {
        $Upload = ($Workflow -split '      - name: Upload integration report')[1]
        $Upload | Should -Match '(?m)^          path: output/testResults/integration-summary.json\s*$'
        $Upload | Should -Not -Match 'PSImmich.Tests.xml|testResults/\*'
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

    It 'records results and skipped test names for <Representation> reports' -ForEach @(
        @{ Representation = 'Skipped'; Attributes = 'skipped="1" ignored="0"'; Cases = '<test-case name="Tag.test" result="Skipped" />'; ExpectedSkipped = 1 }
        @{ Representation = 'Ignored'; Attributes = 'skipped="0" ignored="1"'; Cases = '<test-case name="Tag.test" result="Ignored" />'; ExpectedSkipped = 1 }
        @{ Representation = 'mixed'; Attributes = 'skipped="0" ignored="2"'; Cases = '<test-case name="Tag.test" result="Skipped" /><test-case name="Other.test" result="Ignored" />'; ExpectedSkipped = 2 }
    ) {
        New-Item -ItemType Directory -Force -Path 'output\testResults' | Out-Null
        @"
<test-results total="3" failures="1" errors="0" $Attributes>
  $Cases
</test-results>
"@ | Set-Content -LiteralPath 'output\testResults\PSImmich.Tests.xml'
        & $Summary
        $Text = Get-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Raw
        $Text | Should -Match 'Commit: abcdef'
        $Text | Should -Match 'Server version: 3\.4\.0'
        $Text | Should -Match 'Test step: failure'
        $Text | Should -Match "Total: 3; failures: 1; errors: 0; skipped: $ExpectedSkipped"
        $Text | Should -Match 'Tag\.test'
        $Report = Get-Content -LiteralPath 'output\testResults\integration-summary.json' -Raw | ConvertFrom-Json
        $Report.commit | Should -Be 'abcdef'
        $Report.serverVersion | Should -Be '3.4.0'
        $Report.outcome | Should -Be 'failure'
        $Report.total | Should -Be 3
        $Report.failures | Should -Be 1
        $Report.errors | Should -Be 0
        $Report.skipped | Should -Be $ExpectedSkipped
    }

    It 'does not copy plaintext or XML-escaped assertion secrets into the published report' {
        New-Item -ItemType Directory -Force -Path 'output\testResults' | Out-Null
        @'
<test-results total="1" failures="1" errors="0" skipped="0">
  <test-case name="Session.AccessToken" result="Failure">
    <failure>
      <message>Expected 'synthetic-key&lt;&amp;&quot;&apos;&gt;' but got 'synthetic-actual-token'.</message>
      <stack-trace>synthetic-password&lt;&amp;&gt;</stack-trace>
    </failure>
  </test-case>
</test-results>
'@ | Set-Content -LiteralPath 'output\testResults\PSImmich.Tests.xml'
        & $Summary
        $Published = Get-Content -LiteralPath 'output\testResults\integration-summary.json' -Raw
        $Published | Should -Not -Match 'synthetic-|message|stack-trace|test-case|Session.AccessToken'
        $Report = $Published | ConvertFrom-Json
        @($Report.PSObject.Properties.Name) | Should -HaveCount 7
        $Report.failures | Should -Be 1
        $Report.skipped | Should -Be 0
        Get-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Raw | Should -Not -Match 'synthetic-'
    }

    It 'reports when no test report was produced' {
        & $Summary
        Get-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Raw | Should -Match 'No integration test report was produced'
        Test-Path -LiteralPath 'output\testResults\integration-summary.json' | Should -BeFalse
    }
}
