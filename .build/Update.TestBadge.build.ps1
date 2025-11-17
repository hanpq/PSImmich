param
(
    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $BuildRoot = (property BuildRoot $PSScriptRoot)
)

# Synopsis: Updates the test count badge in README.md based on test results
Task Update_TestBadge_README {
    Write-Build Yellow 'Updating test count badge in README.md'

    $ReadmePath = Join-Path $BuildRoot 'README.md'
    $TestResultsPath = Join-Path $OutputDirectory 'testResults'

    if (-not (Test-Path $ReadmePath))
    {
        Write-Build Red "README.md not found at: $ReadmePath"
        return
    }

    if (-not (Test-Path $TestResultsPath))
    {
        Write-Build Red "Test results directory not found at: $TestResultsPath"
        return
    }

    # Find the most recent NUnit XML test results file
    $NUnitXmlFile = Get-ChildItem -Path $TestResultsPath -Filter 'NUnitXml_*.xml' |
        Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

    if (-not $NUnitXmlFile)
    {
        Write-Build Red "No NUnit XML test results file found in: $TestResultsPath"
        return
    }

    Write-Build Green "Found test results file: $($NUnitXmlFile.Name)"

    # Parse the XML file to get comprehensive test count information
    try
    {
        [xml]$TestResults = Get-Content -Path $NUnitXmlFile.FullName -ErrorAction Stop
        $TestResultsRoot = $TestResults.'test-results'

        # Get individual counts from XML attributes
        $ExecutedTests = [int]$TestResultsRoot.total
        $NotRunTests = [int]$TestResultsRoot.'not-run'
        $SkippedTests = [int]$TestResultsRoot.skipped
        $FailedTests = [int]$TestResultsRoot.failures
        $ErrorTests = [int]$TestResultsRoot.errors
        $IgnoredTests = [int]$TestResultsRoot.ignored
        $InconclusiveTests = [int]$TestResultsRoot.inconclusive

        # Calculate total available tests (executed + not-run)
        $TotalAvailableTests = $ExecutedTests + $NotRunTests

        Write-Build Green "Updating badge with complete test suite count: $TotalAvailableTests"

        # Read current README content
        $ReadmeContent = Get-Content -Path $ReadmePath -Raw -ErrorAction Stop

        # Update the badge with new test count
        # Pattern matches: ![Static Badge2](https://img.shields.io/badge/1103-green?label=Unit%2FQuality%2FIntegration%20tests)
        $BadgePattern = '(!\[Static Badge2\]\(https://img\.shields\.io/badge/)(\d+)(-green\?label=Unit%2FQuality%2FIntegration%20tests\))'
        $NewBadge = "`${1}$TotalAvailableTests`$3"

        if ($ReadmeContent -match $BadgePattern)
        {
            $UpdatedContent = $ReadmeContent -replace $BadgePattern, $NewBadge
            Set-Content -Path $ReadmePath -Value $UpdatedContent -NoNewline -ErrorAction Stop
            Write-Build Green "Successfully updated test badge from $($matches[2]) to $TotalAvailableTests tests"
        }
        else
        {
            Write-Build Yellow 'Test badge pattern not found in README.md - badge may have been already updated or pattern changed'
        }
    }
    catch
    {
        Write-Build Red "Error updating test badge: $($_.Exception.Message)"
        throw
    }
}
