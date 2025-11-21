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

.PARAMETER IncludeSummaryOnly
    Switch to include changes that only affect the summary/description field. By default, summary-only changes are excluded to focus on functional API changes.

.PARAMETER ExclusionsPath
    Path to a JSON file containing API endpoints to exclude from the comparison. The file should contain
    an "ExcludedPaths" array with objects having "Path", "Method", and "Reason" properties.

.EXAMPLE
    .\Compare-OpenApiSpecs.ps1 -OldSpecPath "api.1.128.json" -NewSpecPath "api.2.2.0.json" -OutputPath "api-changes.md"

.EXAMPLE
    .\Compare-OpenApiSpecs.ps1 -OldSpecPath "api.1.128.json" -NewSpecPath "api.2.2.0.json" -IncludeSchemas

.EXAMPLE
    .\Compare-OpenApiSpecs.ps1 -OldSpecPath "api.2.2.0.json" -NewSpecPath "api.2.3.1.json" -IncludeSummaryOnly

.EXAMPLE
    .\Compare-OpenApiSpecs.ps1 -OldSpecPath "api.2.2.0.json" -NewSpecPath "api.2.3.1.json" -ExclusionsPath "exclusions.json"

.NOTES
    Author: PSImmich Development Team
    Version: 2.1.0
    Requires: PowerShell 5.1 or later
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OldSpecPath = '.\api.2.2.0.json',

    [Parameter(Mandatory = $false)]
    [string]$NewSpecPath = '.\api.2.3.1.json',

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeSchemas,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeSummaryOnly,

    [Parameter(Mandatory = $false)]
    [string]$ExclusionsPath
)

# Helper function to safely get nested properties
function Get-SafeProperty
{
    param($Object, $PropertyPath)

    $current = $Object
    foreach ($prop in $PropertyPath -split '\.')
    {
        if ($null -eq $current -or -not $current.PSObject.Properties[$prop])
        {
            return $null
        }
        $current = $current.$prop
    }
    return $current
}

# Helper function to analyze API parameters
function Compare-ApiParameters
{
    param($OldParams, $NewParams)

    $result = @{
        Added    = @()
        Removed  = @()
        Modified = @()
    }

    $oldParamNames = @()
    $newParamNames = @()

    if ($OldParams)
    {
        $oldParamNames = $OldParams | ForEach-Object { $_.name }
    }
    if ($NewParams)
    {
        $newParamNames = $NewParams | ForEach-Object { $_.name }
    }

    # Find added parameters
    $addedParams = $newParamNames | Where-Object { $_ -notin $oldParamNames }
    foreach ($paramName in $addedParams)
    {
        $param = $NewParams | Where-Object { $_.name -eq $paramName }
        $paramInfo = @{
            Name        = $paramName
            Required    = $param.required
            Type        = $param.schema.type
            Description = $param.description
        }
        $result.Added += $paramInfo
    }

    # Find removed parameters
    $removedParams = $oldParamNames | Where-Object { $_ -notin $newParamNames }
    foreach ($paramName in $removedParams)
    {
        $param = $OldParams | Where-Object { $_.name -eq $paramName }
        $paramInfo = @{
            Name        = $paramName
            Required    = $param.required
            Type        = $param.schema.type
            Description = $param.description
        }
        $result.Removed += $paramInfo
    }

    # Find modified parameters
    $commonParams = $oldParamNames | Where-Object { $_ -in $newParamNames }
    foreach ($paramName in $commonParams)
    {
        $oldParam = $OldParams | Where-Object { $_.name -eq $paramName }
        $newParam = $NewParams | Where-Object { $_.name -eq $paramName }

        $changes = @()

        # Check required status
        if ($oldParam.required -ne $newParam.required)
        {
            $changes += @{
                Property = 'Required'
                Old      = $oldParam.required
                New      = $newParam.required
            }
        }

        # Check type changes
        if ($oldParam.schema.type -ne $newParam.schema.type)
        {
            $changes += @{
                Property = 'Type'
                Old      = $oldParam.schema.type
                New      = $newParam.schema.type
            }
        }

        # Check description changes
        if ($oldParam.description -ne $newParam.description)
        {
            $changes += @{
                Property = 'Description'
                Old      = $oldParam.description
                New      = $newParam.description
            }
        }

        if ($changes.Count -gt 0)
        {
            $paramInfo = @{
                Name    = $paramName
                Changes = $changes
            }
            $result.Modified += $paramInfo
        }
    }

    return $result
}

# Helper function to get operation summary
function Get-OperationSummary
{
    param($Operation, $Method, $Path)

    if ($Operation.summary)
    {
        return $Operation.summary
    }
    elseif ($Operation.operationId)
    {
        return $Operation.operationId
    }
    else
    {
        return "$Method $Path"
    }
}

# Function to check if an API should be excluded
function Test-ApiExclusion
{
    param(
        $Method,
        $Path,
        $ExcludedApis
    )

    if (-not $ExcludedApis)
    {
        return $false
    }

    foreach ($exclusion in $ExcludedApis)
    {
        if ($exclusion.Method -eq $Method -and $exclusion.Path -eq $Path)
        {
            return $true
        }
    }

    return $false
}

# Main comparison function
function Compare-OpenApiSpecs
{
    param($OldSpec, $NewSpec)

    # Collect all APIs (method + path combinations)
    $oldApis = @()
    $newApis = @()

    # Extract APIs from old specification
    if ($OldSpec.paths)
    {
        foreach ($path in $OldSpec.paths.PSObject.Properties.Name)
        {
            $pathObj = $OldSpec.paths.$path
            foreach ($method in $pathObj.PSObject.Properties.Name)
            {
                $oldApis += @{
                    Method    = $method.ToUpper()
                    Path      = $path
                    Operation = $pathObj.$method
                    ApiId     = "$($method.ToUpper()) $path"
                }
            }
        }
    }

    # Extract APIs from new specification
    if ($NewSpec.paths)
    {
        foreach ($path in $NewSpec.paths.PSObject.Properties.Name)
        {
            $pathObj = $NewSpec.paths.$path
            foreach ($method in $pathObj.PSObject.Properties.Name)
            {
                $newApis += @{
                    Method    = $method.ToUpper()
                    Path      = $path
                    Operation = $pathObj.$method
                    ApiId     = "$($method.ToUpper()) $path"
                }
            }
        }
    }

    # Find added, removed, and modified APIs
    $oldApiIds = $oldApis | ForEach-Object { $_.ApiId }
    $newApiIds = $newApis | ForEach-Object { $_.ApiId }

    $addedApiIds = $newApiIds | Where-Object { $_ -notin $oldApiIds }
    $removedApiIds = $oldApiIds | Where-Object { $_ -notin $newApiIds }
    $commonApiIds = $oldApiIds | Where-Object { $_ -in $newApiIds }

    $addedApis = $newApis | Where-Object { $_.ApiId -in $addedApiIds }
    $removedApis = $oldApis | Where-Object { $_.ApiId -in $removedApiIds }

    # Check for modifications in common APIs
    $modifiedApis = @()
    foreach ($apiId in $commonApiIds)
    {
        $oldApi = $oldApis | Where-Object { $_.ApiId -eq $apiId }
        $newApi = $newApis | Where-Object { $_.ApiId -eq $apiId }

        # Compare parameters
        $paramComparison = Compare-ApiParameters $oldApi.Operation.parameters $newApi.Operation.parameters

        # Check for deprecation changes
        $deprecationChanged = $oldApi.Operation.deprecated -ne $newApi.Operation.deprecated

        # Check for summary changes (if we're including them)
        $summaryChanged = $false
        if ($IncludeSummaryOnly -and ($oldApi.Operation.summary -ne $newApi.Operation.summary))
        {
            $summaryChanged = $true
        }

        # Determine if this API has significant changes
        $hasChanges = $false
        if ($paramComparison.Added.Count -gt 0 -or
            $paramComparison.Removed.Count -gt 0 -or
            $paramComparison.Modified.Count -gt 0 -or
            $deprecationChanged -or
            $summaryChanged)
        {
            $hasChanges = $true
        }

        if ($hasChanges)
        {
            $modifiedApis += @{
                Method             = $newApi.Method
                Path               = $newApi.Path
                OldOperation       = $oldApi.Operation
                NewOperation       = $newApi.Operation
                ParameterChanges   = $paramComparison
                DeprecationChanged = $deprecationChanged
                SummaryChanged     = $summaryChanged
            }
        }
    }

    # Generate report
    $report = @()
    $report += '# OpenAPI Specification Comparison'
    $report += ''
    $report += "**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # Get version information
    $oldVersion = Get-SafeProperty $OldSpec 'info.version'
    $newVersion = Get-SafeProperty $NewSpec 'info.version'
    $report += "**Comparison:** $oldVersion → $newVersion"
    $report += ''

    # Summary
    $report += '## Summary'
    $report += ''
    $report += '| Change Type | Count |'
    $report += '|-------------|-------|'
    $report += "| Added APIs | $($addedApis.Count) |"
    $report += "| Removed APIs | $($removedApis.Count) |"
    $report += "| Modified APIs | $($modifiedApis.Count) |"
    $report += ''

    # Added APIs
    if ($addedApis.Count -gt 0)
    {
        $report += "## ➕ Added APIs ($($addedApis.Count))"
        $report += ''

        foreach ($api in $addedApis)
        {
            $summary = Get-OperationSummary $api.Operation $api.Method $api.Path
            $report += "### ``$($api.Method) $($api.Path)``"
            $report += "**Summary:** $summary"
            $report += ''

            # Show parameters if any
            if ($api.Operation.parameters)
            {
                $report += '**Query Parameters:**'
                foreach ($param in $api.Operation.parameters)
                {
                    $required = if ($param.required)
                    {
                        ' (required)'
                    }
                    else
                    {
                        ' (optional)'
                    }
                    $type = if ($param.schema.type)
                    {
                        " - $($param.schema.type)"
                    }
                    else
                    {
                        ''
                    }
                    $report += "- ``$($param.name)``$required$type"
                    if ($param.description)
                    {
                        $report += "  - $($param.description)"
                    }
                }
                $report += ''
            }

            # Show deprecation status
            if ($api.Operation.deprecated)
            {
                $report += '⚠️ **Deprecated**'
                $report += ''
            }
        }
    }

    # Removed APIs
    if ($removedApis.Count -gt 0)
    {
        $report += "## ❌ Removed APIs ($($removedApis.Count))"
        $report += ''

        foreach ($api in $removedApis)
        {
            $summary = Get-OperationSummary $api.Operation $api.Method $api.Path
            $report += "### ``$($api.Method) $($api.Path)``"
            $report += "**Summary:** $summary"
            $report += ''

            # Show deprecation status
            if ($api.Operation.deprecated)
            {
                $report += '⚠️ **Deprecated (treat as removed)**'
                $report += ''
            }
        }
    }

    # Modified APIs
    if ($modifiedApis.Count -gt 0)
    {
        $report += "## 🔄 Modified APIs ($($modifiedApis.Count))"
        $report += ''

        foreach ($api in $modifiedApis)
        {
            $summary = Get-OperationSummary $api.NewOperation $api.Method $api.Path
            $report += "### ``$($api.Method) $($api.Path)``"
            $report += "**Summary:** $summary"
            $report += ''

            # Show parameter changes
            if ($api.ParameterChanges.Added.Count -gt 0)
            {
                $report += '**➕ New Query Parameters:**'
                foreach ($param in $api.ParameterChanges.Added)
                {
                    $required = if ($param.Required)
                    {
                        ' (required)'
                    }
                    else
                    {
                        ' (optional)'
                    }
                    $type = if ($param.Type)
                    {
                        " - $($param.Type)"
                    }
                    else
                    {
                        ''
                    }
                    $report += "- ``$($param.Name)``$required$type"
                    if ($param.Description)
                    {
                        $report += "  - $($param.Description)"
                    }
                }
                $report += ''
            }

            if ($api.ParameterChanges.Removed.Count -gt 0)
            {
                $report += '**❌ Removed Query Parameters:**'
                foreach ($param in $api.ParameterChanges.Removed)
                {
                    $required = if ($param.Required)
                    {
                        ' (required)'
                    }
                    else
                    {
                        ' (optional)'
                    }
                    $type = if ($param.Type)
                    {
                        " - $($param.Type)"
                    }
                    else
                    {
                        ''
                    }
                    $report += "- ``$($param.Name)``$required$type"
                }
                $report += ''
            }

            if ($api.ParameterChanges.Modified.Count -gt 0)
            {
                $report += '**🔄 Modified Query Parameters:**'
                foreach ($param in $api.ParameterChanges.Modified)
                {
                    $report += "- ``$($param.Name)``:"
                    foreach ($change in $param.Changes)
                    {
                        $report += "  - $($change.Property): ``$($change.Old)`` → ``$($change.New)``"
                    }
                }
                $report += ''
            }

            # Show deprecation changes
            if ($api.DeprecationChanged)
            {
                if ($api.NewOperation.deprecated)
                {
                    $report += '⚠️ **Now Deprecated**'
                }
                else
                {
                    $report += '✅ **No Longer Deprecated**'
                }
                $report += ''
            }

            # Show summary changes if included
            if ($api.SummaryChanged -and $IncludeSummaryOnly)
            {
                $report += '**Summary Changed:**'
                $report += "- ``$($api.OldOperation.summary)`` → ``$($api.NewOperation.summary)``"
                $report += ''
            }
        }
    }

    $report += '---'
    $report += '*Report generated by Compare-OpenApiSpecs.ps1*'

    return $report -join "`n"
}

# Function to display results in console format
function Show-ConsoleResults
{
    param(
        $AddedApis,
        $RemovedApis,
        $ModifiedApis,
        $OldVersion,
        $NewVersion
    )

    Write-Host "`nAPI Comparison Results: $OldVersion → $NewVersion" -ForegroundColor Cyan
    Write-Host ('=' * 60) -ForegroundColor Cyan

    # Summary
    Write-Host "`nSummary:" -ForegroundColor White
    Write-Host '  Added APIs:    ' -NoNewline; Write-Host "$($AddedApis.Count)" -ForegroundColor Green
    Write-Host '  Removed APIs:  ' -NoNewline; Write-Host "$($RemovedApis.Count)" -ForegroundColor Red
    Write-Host '  Modified APIs: ' -NoNewline; Write-Host "$($ModifiedApis.Count)" -ForegroundColor Yellow

    # Added APIs
    if ($AddedApis.Count -gt 0)
    {
        Write-Host "`n➕ Added APIs ($($AddedApis.Count)):" -ForegroundColor Green
        foreach ($api in $AddedApis)
        {
            $summary = Get-OperationSummary $api.Operation $api.Method $api.Path
            Write-Host "   $($api.Method) $($api.Path)" -ForegroundColor Green
            Write-Host "   └─ $summary" -ForegroundColor Gray

            # Show detailed parameter information
            if ($api.Operation.parameters)
            {
                # Group parameters by type
                $pathParams = @($api.Operation.parameters | Where-Object { $_.in -eq 'path' })
                $queryParams = @($api.Operation.parameters | Where-Object { $_.in -eq 'query' })
                $headerParams = @($api.Operation.parameters | Where-Object { $_.in -eq 'header' })

                if ($pathParams.Count -gt 0)
                {
                    $pathNames = $pathParams | ForEach-Object { $_.name }
                    Write-Host "   └─ Path Parameters: $($pathNames -join ', ')" -ForegroundColor DarkGray
                }
                if ($queryParams.Count -gt 0)
                {
                    $queryNames = $queryParams | ForEach-Object { $_.name }
                    Write-Host "   └─ Query Parameters: $($queryNames -join ', ')" -ForegroundColor DarkGray
                }
                if ($headerParams.Count -gt 0)
                {
                    $headerNames = $headerParams | ForEach-Object { $_.name }
                    Write-Host "   └─ Header Parameters: $($headerNames -join ', ')" -ForegroundColor DarkGray
                }
            }

            # Show request body if present
            if ($api.Operation.requestBody)
            {
                Write-Host '   └─ Request Body: Required' -ForegroundColor DarkGray
            }
        }
    }

    # Removed APIs
    if ($RemovedApis.Count -gt 0)
    {
        Write-Host "`n❌ Removed APIs ($($RemovedApis.Count)):" -ForegroundColor Red
        foreach ($api in $RemovedApis)
        {
            $summary = Get-OperationSummary $api.Operation $api.Method $api.Path
            Write-Host "   $($api.Method) $($api.Path)" -ForegroundColor Red
            Write-Host "   └─ $summary" -ForegroundColor Gray
            if ($api.Operation.deprecated)
            {
                Write-Host '   └─ Deprecated (treat as removed)' -ForegroundColor DarkYellow
            }
        }
    }

    # Modified APIs
    if ($ModifiedApis.Count -gt 0)
    {
        Write-Host "`n🔄 Modified APIs ($($ModifiedApis.Count)):" -ForegroundColor Yellow
        foreach ($api in $ModifiedApis)
        {
            $summary = Get-OperationSummary $api.NewOperation $api.Method $api.Path
            Write-Host "   $($api.Method) $($api.Path)" -ForegroundColor Yellow
            Write-Host "   └─ $summary" -ForegroundColor Gray

            # Show detailed parameter changes
            if ($api.ParameterChanges.Added.Count -gt 0)
            {
                $addedNames = $api.ParameterChanges.Added | ForEach-Object { $_.Name }
                Write-Host "   └─ Added Query Parameters: $($addedNames -join ', ')" -ForegroundColor Green
            }
            if ($api.ParameterChanges.Removed.Count -gt 0)
            {
                $removedNames = $api.ParameterChanges.Removed | ForEach-Object { $_.Name }
                Write-Host "   └─ Removed Query Parameters: $($removedNames -join ', ')" -ForegroundColor Red
            }
            if ($api.ParameterChanges.Modified.Count -gt 0)
            {
                foreach ($modifiedParam in $api.ParameterChanges.Modified)
                {
                    Write-Host "   └─ Modified Query Parameter: $($modifiedParam.Name)" -ForegroundColor Yellow
                    foreach ($change in $modifiedParam.Changes)
                    {
                        $oldValue = if ($change.Old)
                        {
                            $change.Old
                        }
                        else
                        {
                            '<empty>'
                        }
                        $newValue = if ($change.New)
                        {
                            $change.New
                        }
                        else
                        {
                            '<empty>'
                        }
                        Write-Host "      └─ $($change.Property): $oldValue → $newValue" -ForegroundColor DarkYellow
                    }
                }
            }

            # Show deprecation changes
            if ($api.DeprecationChanged)
            {
                if ($api.NewOperation.deprecated)
                {
                    Write-Host '   └─ Status: Now Deprecated' -ForegroundColor DarkYellow
                }
                else
                {
                    Write-Host '   └─ Status: No Longer Deprecated' -ForegroundColor Green
                }
            }
        }
    }

    Write-Host "`n" -NoNewline
}

# Main execution
try
{
    Write-Host 'Loading OpenAPI specifications...' -ForegroundColor Yellow

    # Load specifications
    $oldSpec = Get-Content $OldSpecPath -Raw | ConvertFrom-Json
    $newSpec = Get-Content $NewSpecPath -Raw | ConvertFrom-Json

    Write-Host 'Comparing specifications...' -ForegroundColor Yellow

    # Load exclusions if provided or use default path
    $excludedApis = $null
    $exclusionsFile = if ($ExclusionsPath)
    {
        $ExclusionsPath
    }
    else
    {
        Join-Path $PSScriptRoot 'exclusions.json'
    }

    if (Test-Path $exclusionsFile)
    {
        Write-Host "Loading exclusions from $exclusionsFile..." -ForegroundColor Yellow
        $exclusionsData = Get-Content $exclusionsFile -Raw | ConvertFrom-Json
        $excludedApis = $exclusionsData.ExcludedPaths
        Write-Host "Loaded $($excludedApis.Count) API exclusions" -ForegroundColor Gray
    }
    else
    {
        Write-Host "No exclusions file found at $exclusionsFile" -ForegroundColor Gray
    }

    # Get version information for console output
    $oldVersion = Get-SafeProperty $oldSpec 'info.version'
    $newVersion = Get-SafeProperty $newSpec 'info.version'

    # Collect APIs for both console and markdown output
    $oldApis = @()
    $newApis = @()

    # Extract APIs from specifications
    if ($oldSpec.paths)
    {
        foreach ($path in $oldSpec.paths.PSObject.Properties.Name)
        {
            $pathObj = $oldSpec.paths.$path
            foreach ($method in $pathObj.PSObject.Properties.Name)
            {
                $oldApis += @{
                    Method    = $method.ToUpper()
                    Path      = $path
                    Operation = $pathObj.$method
                    ApiId     = "$($method.ToUpper()) $path"
                }
            }
        }
    }

    if ($newSpec.paths)
    {
        foreach ($path in $newSpec.paths.PSObject.Properties.Name)
        {
            $pathObj = $newSpec.paths.$path
            foreach ($method in $pathObj.PSObject.Properties.Name)
            {
                $newApis += @{
                    Method    = $method.ToUpper()
                    Path      = $path
                    Operation = $pathObj.$method
                    ApiId     = "$($method.ToUpper()) $path"
                }
            }
        }
    }

    # Find added, removed, and modified APIs
    $oldApiIds = $oldApis | ForEach-Object { $_.ApiId }
    $newApiIds = $newApis | ForEach-Object { $_.ApiId }

    $addedApiIds = $newApiIds | Where-Object { $_ -notin $oldApiIds }
    $removedApiIds = $oldApiIds | Where-Object { $_ -notin $newApiIds }
    $commonApiIds = $oldApiIds | Where-Object { $_ -in $newApiIds }

    $addedApis = @($newApis | Where-Object { $_.ApiId -in $addedApiIds -and -not (Test-ApiExclusion $_.Method $_.Path $excludedApis) })
    $removedApis = @($oldApis | Where-Object { $_.ApiId -in $removedApiIds -and -not (Test-ApiExclusion $_.Method $_.Path $excludedApis) })

    # Check for modifications in common APIs and categorize deprecated APIs as removed
    $modifiedApis = @()
    $deprecatedApis = @()

    foreach ($apiId in $commonApiIds)
    {
        $oldApi = $oldApis | Where-Object { $_.ApiId -eq $apiId }
        $newApi = $newApis | Where-Object { $_.ApiId -eq $apiId }

        # Check if API became deprecated (treat as removed)
        if (-not $oldApi.Operation.deprecated -and $newApi.Operation.deprecated -and -not (Test-ApiExclusion $newApi.Method $newApi.Path $excludedApis))
        {
            # Add to deprecated list using the new (deprecated) API info
            $deprecatedApis += @{
                Method    = $newApi.Method
                Path      = $newApi.Path
                Operation = $newApi.Operation
                ApiId     = $newApi.ApiId
            }
            continue
        }

        # Compare parameters
        $paramComparison = Compare-ApiParameters $oldApi.Operation.parameters $newApi.Operation.parameters

        # Check for deprecation changes (only for APIs that were already deprecated or became un-deprecated)
        $deprecationChanged = $oldApi.Operation.deprecated -ne $newApi.Operation.deprecated

        # Check for summary changes (if we're including them)
        $summaryChanged = $false
        if ($IncludeSummaryOnly -and ($oldApi.Operation.summary -ne $newApi.Operation.summary))
        {
            $summaryChanged = $true
        }

        # Determine if this API has significant changes
        $hasChanges = $false
        if ($paramComparison.Added.Count -gt 0 -or
            $paramComparison.Removed.Count -gt 0 -or
            $paramComparison.Modified.Count -gt 0 -or
            $deprecationChanged -or
            $summaryChanged)
        {
            $hasChanges = $true
        }

        if ($hasChanges -and -not (Test-ApiExclusion $newApi.Method $newApi.Path $excludedApis))
        {
            $modifiedApis += @{
                Method             = $newApi.Method
                Path               = $newApi.Path
                OldOperation       = $oldApi.Operation
                NewOperation       = $newApi.Operation
                ParameterChanges   = $paramComparison
                DeprecationChanged = $deprecationChanged
                SummaryChanged     = $summaryChanged
            }
        }
    }

    # Add deprecated APIs to removed list
    $removedApis = $removedApis + $deprecatedApis

    # Output result
    if ($OutputPath)
    {
        # Generate markdown report for file output
        $report = Compare-OpenApiSpecs $oldSpec $newSpec
        $report | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "Comparison complete! Report saved to $OutputPath" -ForegroundColor Green

        # Also show console summary
        Show-ConsoleResults $addedApis $removedApis $modifiedApis $oldVersion $newVersion
    }
    else
    {
        # Show console output only
        Write-Host 'Comparison complete!' -ForegroundColor Green
        Show-ConsoleResults $addedApis $removedApis $modifiedApis $oldVersion $newVersion
    }
}
catch
{
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}
