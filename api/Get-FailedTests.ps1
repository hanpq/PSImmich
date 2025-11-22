#requires -Version 5.1

<#
.SYNOPSIS
    Extracts failed test results in JSON format for analysis

.DESCRIPTION
    Parses Pester test results from the output\testResults folder and extracts
    only failed tests with detailed information useful for troubleshooting.
    
    The script imports the PesterObject XML file which contains rich test metadata
    and outputs failed tests as structured JSON data including:
    
    - Test name and full hierarchy path
    - Source file and line number  
    - Test duration
    - Error details including exception messages
    - Test code and context information

.PARAMETER ResultsPath
    Path to the testResults directory. Defaults to output\testResults relative to script location.

.PARAMETER LatestOnly
    Use only the most recent test results file. Default behavior.

.PARAMETER IncludeContext
    Include additional test metadata like execution time and framework data.

.EXAMPLE
    .\Get-FailedTests.ps1

    Outputs failed test analysis as JSON to console

.EXAMPLE
    .\Get-FailedTests.ps1 -IncludeContext

    Includes additional metadata in the JSON output

.EXAMPLE
    .\Get-FailedTests.ps1 | ConvertFrom-Json

    Parse JSON output for programmatic analysis
#>[CmdletBinding()]
param(
    [string]$ResultsPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'output\testResults'),
    [switch]$LatestOnly = $true,
    [switch]$IncludeContext
)

#region Helper Functions

function Get-LatestPesterResults {
    param([string]$Path)
    
    $pesterFiles = Get-ChildItem -Path $Path -Filter 'PesterObject_*.xml' | Sort-Object LastWriteTime -Descending
    
    if (-not $pesterFiles) {
        throw "No Pester result files found in $Path"
    }
    
    $latestFile = $pesterFiles[0]
    
    return @{
        Results = Import-Clixml $latestFile.FullName
        SourceFile = $latestFile.Name
        GeneratedAt = $latestFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
    }
}

function ConvertTo-FailedTestObject {
    param($Test, $PesterResults, [switch]$IncludeContext)
    
    # Extract error details
    $errorDetails = @()
    if ($Test.ErrorRecord -and $Test.ErrorRecord.Count -gt 0) {
        foreach ($error in $Test.ErrorRecord) {
            if ($error -is [string]) {
                $errorDetails += $error
            } elseif ($error.Exception.Message) {
                $errorObj = @{
                    message = $error.Exception.Message
                }
                if ($error.FullyQualifiedErrorId) {
                    $errorObj.errorId = $error.FullyQualifiedErrorId
                }
                if ($error.ScriptStackTrace) {
                    $errorObj.stackTrace = $error.ScriptStackTrace -split "`n"
                } elseif ($error.Exception.StackTrace) {
                    $errorObj.stackTrace = $error.Exception.StackTrace -split "`n"
                }
                $errorDetails += $errorObj
            }
        }
    }
    
    # Get source file information
    $sourceContainer = Get-TestSourceFile -Test $Test -PesterResults $PesterResults
    
    $testObject = @{
        name = $Test.Name
        path = $Test.Path
        expandedName = $Test.ExpandedName
        sourceFile = if ($sourceContainer) { Split-Path $sourceContainer.Item.FullName -Leaf } else { $null }
        fullPath = if ($sourceContainer) { $sourceContainer.Item.FullName } else { $null }
        line = $Test.StartLine
        duration = $Test.Duration.TotalMilliseconds
        durationFormatted = "$([math]::Round($Test.Duration.TotalMilliseconds, 4))ms"
        errors = $errorDetails
        code = if ($Test.ScriptBlock) { $Test.ScriptBlock.Trim() } else { $null }
        result = $Test.Result
    }
    
    if ($IncludeContext) {
        $testObject.executedAt = $Test.ExecutedAt.ToString('yyyy-MM-dd HH:mm:ss')
        $testObject.blockName = $Test.Block.Name
        $testObject.hasData = [bool]$Test.Data
        $testObject.hasFrameworkData = [bool]$Test.FrameworkData
    }
    
    return $testObject
}

function Get-TestSourceFile {
    param($Test, $PesterResults)

    # Try to find source file by correlating test path with containers
    # Most tests are in Public.Tests.ps1, Integration tests are in integration.tests.ps1, etc.
    $testPath = $Test.Path -join " "

    if ($testPath -match "Integration") {
        return $PesterResults.Containers | Where-Object { $_.Item.FullName -like "*integration.tests.ps1" } | Select-Object -First 1
    } elseif ($testPath -match "QA|module") {
        return $PesterResults.Containers | Where-Object { $_.Item.FullName -like "*module.tests.ps1" } | Select-Object -First 1
    } elseif ($testPath -match "Private") {
        return $PesterResults.Containers | Where-Object { $_.Item.FullName -like "*Private.Tests.ps1" } | Select-Object -First 1
    } else {
        # Most tests are in Public.Tests.ps1
        return $PesterResults.Containers | Where-Object { $_.Item.FullName -like "*Public.Tests.ps1" } | Select-Object -First 1
    }
}

#endregion

#region Main Execution

try {
    # Validate results path
    if (-not (Test-Path $ResultsPath)) {
        throw "Test results path not found: $ResultsPath"
    }

    # Import test results
    $pesterData = Get-LatestPesterResults -Path $ResultsPath
    $pesterResults = $pesterData.Results

    # Build JSON response object
    $response = @{
        metadata = @{
            sourceFile = $pesterData.SourceFile
            generatedAt = $pesterData.GeneratedAt
            analysisTimestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
        summary = @{
            total = $pesterResults.AllTests.Count
            passed = $pesterResults.PassedCount
            failed = $pesterResults.FailedCount
            skipped = $pesterResults.SkippedCount
            notRun = $pesterResults.NotRunCount
        }
        failedTests = @()
    }

    # Process each failed test
    if ($pesterResults.FailedCount -gt 0) {
        foreach ($failedTest in $pesterResults.Failed) {
            $testObject = ConvertTo-FailedTestObject -Test $failedTest -PesterResults $pesterResults -IncludeContext:$IncludeContext
            $response.failedTests += $testObject
        }
    }

    # Output as JSON
    $response | ConvertTo-Json -Depth 10
}
catch {
    $errorResponse = @{
        error = @{
            message = $_.Exception.Message
            timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
    }
    $errorResponse | ConvertTo-Json -Depth 5
    exit 1
}

#endregion
