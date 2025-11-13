<#
.SYNOPSIS
    Compares two OpenAPI specification files and generates a comprehensive markdown summary of differences.

.DESCRIPTION
    This script compares two OpenAPI JSON specification files and generates a detailed markdown report
    showing added/removed paths, parameter changes, schema modifications, and other relevant changes.
    The output is formatted for easy readability and can be used for release notes or migration guides.

.PARAMETER OldSpecPath
    Path to the older OpenAPI specification file (baseline for comparison).

.PARAMETER NewSpecPath
    Path to the newer OpenAPI specification file (target for comparison).

.PARAMETER OutputPath
    Optional path for the output markdown file. If not specified, outputs to console.

.PARAMETER IncludeSchemas
    Switch to include schema (component) changes in the comparison. Default is false for cleaner output.

.EXAMPLE
    .\Compare-OpenApiSpecs.ps1 -OldSpecPath "api.1.128.json" -NewSpecPath "api.2.2.0.json" -OutputPath "api-changes.md"

.EXAMPLE
    .\Compare-OpenApiSpecs.ps1 -OldSpecPath "api.1.128.json" -NewSpecPath "api.2.2.0.json" -IncludeSchemas

.NOTES
    Author: PSImmich Development Team
    Version: 1.0.0
    Requires: PowerShell 5.1 or later
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OldSpecPath,

    [Parameter(Mandatory = $true)]
    [string]$NewSpecPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeSchemas
)

# Helper function to safely get nested properties
function Get-SafeProperty {
    param($Object, $PropertyPath)

    $current = $Object
    foreach ($prop in $PropertyPath -split '\.') {
        if ($null -eq $current -or -not $current.PSObject.Properties[$prop]) {
            return $null
        }
        $current = $current.$prop
    }
    return $current
}

# Helper function to compare parameters
function Compare-Parameters {
    param($OldParams, $NewParams, $PathInfo)

    $changes = @()
    $oldParamNames = @()
    $newParamNames = @()

    if ($OldParams) { $oldParamNames = $OldParams | ForEach-Object { $_.name } }
    if ($NewParams) { $newParamNames = $NewParams | ForEach-Object { $_.name } }

    # Find added parameters
    $addedParams = $newParamNames | Where-Object { $_ -notin $oldParamNames }
    foreach ($paramName in $addedParams) {
        $param = $NewParams | Where-Object { $_.name -eq $paramName }
        $required = if ($param.required) { " (required)" } else { " (optional)" }
        $changes += "  - ➕ **Added parameter**: ``$paramName``$required"
        if ($param.schema.type) {
            $changes += "    - Type: ``$($param.schema.type)``"
        }
        if ($param.description) {
            $changes += "    - Description: $($param.description)"
        }
    }

    # Find removed parameters
    $removedParams = $oldParamNames | Where-Object { $_ -notin $newParamNames }
    foreach ($paramName in $removedParams) {
        $changes += "  - ❌ **Removed parameter**: ``$paramName``"
    }

    # Find modified parameters
    $commonParams = $oldParamNames | Where-Object { $_ -in $newParamNames }
    foreach ($paramName in $commonParams) {
        $oldParam = $OldParams | Where-Object { $_.name -eq $paramName }
        $newParam = $NewParams | Where-Object { $_.name -eq $paramName }

        $paramChanges = @()

        # Check required status
        if ($oldParam.required -ne $newParam.required) {
            $oldReq = if ($oldParam.required) { "required" } else { "optional" }
            $newReq = if ($newParam.required) { "required" } else { "optional" }
            $paramChanges += "    - Required status: ``$oldReq`` → ``$newReq``"
        }

        # Check type changes
        if ($oldParam.schema.type -ne $newParam.schema.type) {
            $paramChanges += "    - Type: ``$($oldParam.schema.type)`` → ``$($newParam.schema.type)``"
        }

        # Check format changes
        if ($oldParam.schema.format -ne $newParam.schema.format) {
            $paramChanges += "    - Format: ``$($oldParam.schema.format)`` → ``$($newParam.schema.format)``"
        }

        if ($paramChanges.Count -gt 0) {
            $changes += "  - 🔄 **Modified parameter**: ``$paramName``"
            $changes += $paramChanges
        }
    }

    return $changes
}

# Helper function to get operation summary
function Get-OperationSummary {
    param($Operation, $Method, $Path)

    if ($Operation.summary) {
        return $Operation.summary
    }
    elseif ($Operation.operationId) {
        return $Operation.operationId
    }
    else {
        return "$Method $Path"
    }
}

# Main comparison function
function Compare-OpenApiSpecs {
    param($OldSpec, $NewSpec)

    $report = @()
    $report += "# OpenAPI Specification Comparison"
    $report += ""
    $report += "**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # Get version information
    $oldVersion = Get-SafeProperty $OldSpec 'info.version'
    $newVersion = Get-SafeProperty $NewSpec 'info.version'
    $report += "**Comparison:** $oldVersion → $newVersion"
    $report += ""

    # Get all paths
    $oldPaths = if ($OldSpec.paths) { $OldSpec.paths.PSObject.Properties.Name } else { @() }
    $newPaths = if ($NewSpec.paths) { $NewSpec.paths.PSObject.Properties.Name } else { @() }

    # Find added and removed paths
    $addedPaths = $newPaths | Where-Object { $_ -notin $oldPaths }
    $removedPaths = $oldPaths | Where-Object { $_ -notin $newPaths }
    $commonPaths = $oldPaths | Where-Object { $_ -in $newPaths }

    # We'll add the summary section after calculating modified paths

    # Added paths
    if ($addedPaths.Count -gt 0) {
        $report += "## ➕ Added Paths ($($addedPaths.Count))"
        $report += ""

        foreach ($path in $addedPaths) {
            $report += "### ``$path``"
            $pathObj = $NewSpec.paths.$path

            foreach ($method in $pathObj.PSObject.Properties.Name) {
                $operation = $pathObj.$method
                $summary = Get-OperationSummary $operation $method.ToUpper() $path
                $report += "- **$($method.ToUpper())**: $summary"

                if ($operation.parameters) {
                    $report += "  - **Parameters:**"
                    foreach ($param in $operation.parameters) {
                        $required = if ($param.required) { " (required)" } else { " (optional)" }
                        $type = if ($param.schema.type) { " - $($param.schema.type)" } else { "" }
                        $report += "    - ``$($param.name)``$required$type"
                    }
                }
            }
            $report += ""
        }
    }

    # Removed paths
    if ($removedPaths.Count -gt 0) {
        $report += "## ❌ Removed Paths ($($removedPaths.Count))"
        $report += ""

        foreach ($path in $removedPaths) {
            $report += "### ``$path``"
            $pathObj = $OldSpec.paths.$path

            foreach ($method in $pathObj.PSObject.Properties.Name) {
                $operation = $pathObj.$method
                $summary = Get-OperationSummary $operation $method.ToUpper() $path
                $report += "- **$($method.ToUpper())**: $summary"
            }
            $report += ""
        }
    }

    # Modified paths
    $modifiedPaths = @()
    foreach ($path in $commonPaths) {
        $oldPathObj = $OldSpec.paths.$path
        $newPathObj = $NewSpec.paths.$path

        $pathChanges = @()

        # Get all methods for this path
        $oldMethods = $oldPathObj.PSObject.Properties.Name
        $newMethods = $newPathObj.PSObject.Properties.Name

        # Find added methods
        $addedMethods = $newMethods | Where-Object { $_ -notin $oldMethods }
        foreach ($method in $addedMethods) {
            $operation = $newPathObj.$method
            $summary = Get-OperationSummary $operation $method.ToUpper() $path
            $pathChanges += "- ➕ **Added method**: **$($method.ToUpper())** - $summary"
        }

        # Find removed methods
        $removedMethods = $oldMethods | Where-Object { $_ -notin $newMethods }
        foreach ($method in $removedMethods) {
            $operation = $oldPathObj.$method
            $summary = Get-OperationSummary $operation $method.ToUpper() $path
            $pathChanges += "- ❌ **Removed method**: **$($method.ToUpper())** - $summary"
        }

        # Check modified methods
        $commonMethods = $oldMethods | Where-Object { $_ -in $newMethods }
        foreach ($method in $commonMethods) {
            $oldOperation = $oldPathObj.$method
            $newOperation = $newPathObj.$method

            # Compare parameters
            $paramChanges = Compare-Parameters $oldOperation.parameters $newOperation.parameters "$path $method"
            if ($paramChanges.Count -gt 0) {
                $summary = Get-OperationSummary $newOperation $method.ToUpper() $path
                $pathChanges += "- 🔄 **Modified method**: **$($method.ToUpper())** - $summary"
                $pathChanges += $paramChanges
            }

            # Check for other operation changes
            $operationChanges = @()

            # Check summary changes
            if ($oldOperation.summary -ne $newOperation.summary) {
                $operationChanges += "  - Summary: ``$($oldOperation.summary)`` → ``$($newOperation.summary)``"
            }

            # Check deprecated status
            if ($oldOperation.deprecated -ne $newOperation.deprecated) {
                $depStatus = if ($newOperation.deprecated) { "deprecated" } else { "not deprecated" }
                $operationChanges += "  - Deprecated status: $depStatus"
            }

            if ($operationChanges.Count -gt 0 -and $paramChanges.Count -eq 0) {
                $summary = Get-OperationSummary $newOperation $method.ToUpper() $path
                $pathChanges += "- 🔄 **Modified method**: **$($method.ToUpper())** - $summary"
                $pathChanges += $operationChanges
            }
        }

        if ($pathChanges.Count -gt 0) {
            $modifiedPaths += [PSCustomObject]@{
                Path = $path
                Changes = $pathChanges
            }
        }
    }

    # Insert summary section after header but before other sections
    $summarySection = @()
    $summarySection += "## Summary"
    $summarySection += ""
    $summarySection += "| Change Type | Count |"
    $summarySection += "|-------------|-------|"
    $summarySection += "| Added Paths | $($addedPaths.Count) |"
    $summarySection += "| Removed Paths | $($removedPaths.Count) |"
    $summarySection += "| Modified Paths | $($modifiedPaths.Count) |"
    $summarySection += ""

    # Insert summary after the header (first 3 lines)
    $headerLines = $report[0..2]
    $contentLines = if ($report.Count -gt 3) { $report[3..($report.Count-1)] } else { @() }
    $report = $headerLines + $summarySection + $contentLines

    if ($modifiedPaths.Count -gt 0) {
        $report += "## 🔄 Modified Paths ($($modifiedPaths.Count))"
        $report += ""

        foreach ($pathInfo in $modifiedPaths) {
            $report += "### ``$($pathInfo.Path)``"
            $report += ""
            $report += $pathInfo.Changes
            $report += ""
        }
    }

    # Schema changes (if requested)
    if ($IncludeSchemas -and $OldSpec.components.schemas -and $NewSpec.components.schemas) {
        $oldSchemas = $OldSpec.components.schemas.PSObject.Properties.Name
        $newSchemas = $NewSpec.components.schemas.PSObject.Properties.Name

        $addedSchemas = $newSchemas | Where-Object { $_ -notin $oldSchemas }
        $removedSchemas = $oldSchemas | Where-Object { $_ -notin $newSchemas }

        if ($addedSchemas.Count -gt 0 -or $removedSchemas.Count -gt 0) {
            $report += "## 📋 Schema Changes"
            $report += ""

            if ($addedSchemas.Count -gt 0) {
                $report += "### ➕ Added Schemas ($($addedSchemas.Count))"
                foreach ($schema in $addedSchemas) {
                    $report += "- ``$schema``"
                }
                $report += ""
            }

            if ($removedSchemas.Count -gt 0) {
                $report += "### ❌ Removed Schemas ($($removedSchemas.Count))"
                foreach ($schema in $removedSchemas) {
                    $report += "- ``$schema``"
                }
                $report += ""
            }
        }
    }

    # Add footer
    $report += "---"
    $report += "*Report generated by Compare-OpenApiSpecs.ps1*"

    return $report -join "`n"
}

# Main execution
try {
    Write-Host "Loading OpenAPI specifications..." -ForegroundColor Yellow

    if (-not (Test-Path $OldSpecPath)) {
        throw "Old specification file not found: $OldSpecPath"
    }

    if (-not (Test-Path $NewSpecPath)) {
        throw "New specification file not found: $NewSpecPath"
    }

    $oldSpec = Get-Content $OldSpecPath -Raw | ConvertFrom-Json
    $newSpec = Get-Content $NewSpecPath -Raw | ConvertFrom-Json

    Write-Host "Comparing specifications..." -ForegroundColor Yellow
    $report = Compare-OpenApiSpecs $oldSpec $newSpec

    if ($OutputPath) {
        Write-Host "Writing report to: $OutputPath" -ForegroundColor Green
        $report | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "Comparison complete! Report saved to $OutputPath" -ForegroundColor Green
    }
    else {
        Write-Host "Comparison complete!" -ForegroundColor Green
        Write-Host "`n" -NoNewline
        Write-Output $report
    }
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}
