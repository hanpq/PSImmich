#requires -Version 5.1

<#
.SYNOPSIS
    Simple API work item analyzer for PSImmich module maintenance

.DESCRIPTION
    Analyzes the latest API specification against current PSImmich implementation
    to generate a focused work item list. Shows only what needs attention:

    - Missing APIs that should be implemented
    - Deprecated APIs that are still implemented (should be removed)
    - Excludes APIs listed in exclusions.json

    The goal is to provide a clean, actionable todo list for module maintenance.

.EXAMPLE
    .\Analyze-PSImmichAPIv2.ps1

    Runs analysis using the latest API spec and current source code
#>

[CmdletBinding()]
param()

#region Helper Functions

function Get-LatestApiSpec
{
    $apiFiles = Get-ChildItem -Path $PSScriptRoot -Filter 'api.*.json' | Sort-Object LastWriteTime -Descending
    if (-not $apiFiles)
    {
        throw "No API specification files found in $PSScriptRoot"
    }

    $latestFile = $apiFiles[0]
    Write-Host 'Using API specification: ' -NoNewline -ForegroundColor Cyan
    Write-Host $latestFile.Name -ForegroundColor White

    return Get-Content $latestFile.FullName | ConvertFrom-Json
}

function Get-ExclusionConfig
{
    $exclusionFile = Join-Path $PSScriptRoot 'exclusions.json'
    if (Test-Path $exclusionFile)
    {
        Write-Host 'Loading exclusions from: ' -NoNewline -ForegroundColor Cyan
        Write-Host 'exclusions.json' -ForegroundColor White
        return Get-Content $exclusionFile | ConvertFrom-Json
    }

    Write-Warning 'No exclusions.json found - no APIs will be excluded'
    return @{ ExcludedPaths = @(); ManualMappings = @() }
}

function Get-ImplementedAPIs
{
    $sourcePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'source\Public'
    if (-not (Test-Path $sourcePath))
    {
        throw "Source path not found: $sourcePath"
    }

    Write-Host 'Analyzing source code in: ' -NoNewline -ForegroundColor Cyan
    Write-Host 'source\Public' -ForegroundColor White

    $implementedAPIs = @()
    $codeFiles = Get-ChildItem $sourcePath -Recurse -Filter '*.ps1'

    foreach ($file in $codeFiles)
    {
        try
        {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $file.FullName, [ref]$null, [ref]$null
            )

            # Get function name
            $functionDef = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $false) | Select-Object -First 1

            if (-not $functionDef)
            {
                continue 
            }

            # Find API calls
            $apiCalls = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                    $args[0].GetCommandName() -eq 'InvokeImmichRestMethod'
                }, $true)

            foreach ($call in $apiCalls)
            {
                $method = $null
                $path = $null

                # Extract method and path parameters
                for ($i = 0; $i -lt $call.CommandElements.Count; $i++)
                {
                    $element = $call.CommandElements[$i]
                    $elementText = if ($element.Value)
                    {
                        $element.Value 
                    }
                    else
                    {
                        $element.Extent.Text 
                    }

                    if ($elementText -eq '-Method' -and ($i + 1) -lt $call.CommandElements.Count)
                    {
                        $methodElement = $call.CommandElements[$i + 1]
                        $method = if ($methodElement.Value)
                        {
                            $methodElement.Value 
                        }
                        else
                        {
                            $methodElement.Extent.Text 
                        }
                        $method = $method -replace "['`"]", '' | ForEach-Object { $_.ToUpper() }
                    }
                    elseif ($elementText -eq '-RelativePath' -and ($i + 1) -lt $call.CommandElements.Count)
                    {
                        $pathElement = $call.CommandElements[$i + 1]
                        $path = if ($pathElement.Value)
                        {
                            $pathElement.Value 
                        }
                        else
                        {
                            $pathElement.Extent.Text 
                        }
                        $path = $path -replace "['`"]", ''
                    }
                }

                if ($method -and $path)
                {
                    $implementedAPIs += [PSCustomObject]@{
                        Method   = $method
                        Path     = $path
                        Function = $functionDef.Name
                        File     = $file.Name
                    }
                }
            }
        }
        catch
        {
            Write-Warning "Failed to parse $($file.Name): $($_.Exception.Message)"
        }
    }

    return $implementedAPIs
}

function Test-APIExclusion
{
    param($Method, $Path, $Exclusions)

    # Check excluded paths
    $excluded = $Exclusions.ExcludedPaths | Where-Object {
        $_.Path -eq $Path -and $_.Method -eq $Method
    }

    # Check manual mappings (these are also considered "handled")
    $mapped = $Exclusions.ManualMappings | Where-Object {
        $_.Path -eq $Path -and $_.Method -eq $Method
    }

    return [bool]($excluded -or $mapped)
}

function Test-APIMatch
{
    param($SpecPath, $SpecMethod, $ImplPath, $ImplMethod)

    if ($SpecMethod -ne $ImplMethod)
    {
        return $false
    }

    # Direct match
    if ($SpecPath -eq $ImplPath)
    {
        return $true
    }

    # Pattern match for parameterized paths
    $pattern = $SpecPath -replace '\{[^}]+\}', '*'
    return $ImplPath -like $pattern
}

#endregion

#region Main Analysis

try
{
    Write-Host "`n=== PSImmich API Work Item Analysis ===" -ForegroundColor Yellow
    Write-Host "Generating focused todo list for module maintenance`n" -ForegroundColor Gray

    # Load data
    $apiSpec = Get-LatestApiSpec
    $exclusions = Get-ExclusionConfig
    $implementedAPIs = Get-ImplementedAPIs

    Write-Host "`n=== Analysis Results ===" -ForegroundColor Yellow

    $workItems = @()
    $processedCount = 0

    # Analyze each API endpoint in the specification
    foreach ($pathKey in $apiSpec.paths.PSObject.Properties.Name)
    {
        $pathObject = $apiSpec.paths.$pathKey

        foreach ($methodKey in $pathObject.PSObject.Properties.Name)
        {
            if ($methodKey -notin @('get', 'post', 'put', 'delete', 'patch'))
            {
                continue
            }

            $processedCount++
            $methodObject = $pathObject.$methodKey
            $method = $methodKey.ToUpper()
            $path = $pathKey

            # Skip if excluded
            if (Test-APIExclusion -Method $method -Path $path -Exclusions $exclusions)
            {
                continue
            }

            # Check if implemented
            $matchingImpl = $implementedAPIs | Where-Object {
                Test-APIMatch -SpecPath $path -SpecMethod $method -ImplPath $_.Path -ImplMethod $_.Method
            }

            $isImplemented = [bool]$matchingImpl
            $isDeprecated = [bool]$methodObject.deprecated

            # Determine work item type
            $workItemType = $null
            $priority = 'Medium'

            if ($isDeprecated -and $isImplemented)
            {
                $workItemType = 'Remove'
                $priority = 'High'
            }
            elseif (-not $isDeprecated -and -not $isImplemented)
            {
                $workItemType = 'Implement'
                $priority = 'Medium'
            }

            # Add work item if action needed
            if ($workItemType)
            {
                $tags = $methodObject.tags -join ', '
                $description = $methodObject.summary ?? $methodObject.description ?? 'No description available'

                $workItems += [PSCustomObject]@{
                    Type            = $workItemType
                    Priority        = $priority
                    Method          = $method
                    Path            = $path
                    OperationId     = $methodObject.operationId
                    Tags            = $tags
                    Description     = $description
                    CurrentFunction = if ($matchingImpl)
                    {
                        ($matchingImpl.Function -join ', ') 
                    }
                    else
                    {
                        '' 
                    }
                    DeprecatedSince = if ($isDeprecated)
                    {
                        $methodObject.'x-immich-lifecycle'.deprecatedAt 
                    }
                    else
                    {
                        '' 
                    }
                }
            }
        }
    }

    # Display results
    if ($workItems.Count -eq 0)
    {
        Write-Host '🎉 ' -NoNewline -ForegroundColor Green
        Write-Host 'No work items found! Module is current with API specification.' -ForegroundColor Green
    }
    else
    {
        # Summary
        $removeCount = ($workItems | Where-Object Type -EQ 'Remove').Count
        $implementCount = ($workItems | Where-Object Type -EQ 'Implement').Count

        Write-Host '📋 Work Items Summary:' -ForegroundColor Cyan
        if ($removeCount -gt 0)
        {
            Write-Host '   • Remove deprecated APIs: ' -NoNewline -ForegroundColor Red
            Write-Host $removeCount -ForegroundColor White
        }
        if ($implementCount -gt 0)
        {
            Write-Host '   • Implement missing APIs: ' -NoNewline -ForegroundColor Yellow
            Write-Host $implementCount -ForegroundColor White
        }
        Write-Host ''

        # Group and display work items
        $removeItems = $workItems | Where-Object Type -EQ 'Remove' | Sort-Object Path
        $implementItems = $workItems | Where-Object Type -EQ 'Implement' | Sort-Object Tags, Path

        if ($removeItems)
        {
            Write-Host '🗑️  REMOVE - Deprecated APIs still implemented:' -ForegroundColor Red
            foreach ($item in $removeItems)
            {
                Write-Host "   $($item.Method) $($item.Path)" -ForegroundColor Red
                Write-Host '      Function: ' -NoNewline -ForegroundColor Gray
                Write-Host $item.CurrentFunction -ForegroundColor White
                if ($item.DeprecatedSince)
                {
                    Write-Host '      Deprecated since: ' -NoNewline -ForegroundColor Gray
                    Write-Host $item.DeprecatedSince -ForegroundColor DarkYellow
                }
                Write-Host ''
            }
        }

        if ($implementItems)
        {
            Write-Host '➕ IMPLEMENT - Missing API coverage:' -ForegroundColor Yellow

            # Group by tags for better organization
            $groupedItems = $implementItems | Group-Object Tags
            foreach ($group in $groupedItems)
            {
                $tagName = if ($group.Name)
                {
                    $group.Name 
                }
                else
                {
                    'Untagged' 
                }
                Write-Host "   📁 $tagName" -ForegroundColor Cyan

                foreach ($item in $group.Group)
                {
                    Write-Host "      $($item.Method) $($item.Path)" -ForegroundColor Yellow
                    if ($item.OperationId)
                    {
                        Write-Host '         Operation: ' -NoNewline -ForegroundColor Gray
                        Write-Host $item.OperationId -ForegroundColor White
                    }
                    $shortDesc = if ($item.Description.Length -gt 80)
                    {
                        $item.Description.Substring(0, 77) + '...'
                    }
                    else
                    {
                        $item.Description
                    }
                    Write-Host "         $shortDesc" -ForegroundColor Gray
                }
                Write-Host ''
            }
        }
    }

    # Final statistics
    Write-Host '📊 Analysis Statistics:' -ForegroundColor Cyan
    Write-Host "   • Total API endpoints processed: $processedCount" -ForegroundColor White
    Write-Host '   • Excluded from analysis: ' -NoNewline -ForegroundColor White
    Write-Host $exclusions.ExcludedPaths.Count -ForegroundColor Gray
    Write-Host '   • Work items identified: ' -NoNewline -ForegroundColor White
    Write-Host $workItems.Count -ForegroundColor $(if ($workItems.Count -eq 0)
        {
            'Green' 
        }
        else
        {
            'Yellow' 
        })
}
catch
{
    Write-Error "Analysis failed: $($_.Exception.Message)"
    exit 1
}

#endregion
