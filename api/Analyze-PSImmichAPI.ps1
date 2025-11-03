#requires -Version 5.1

<#
.SYNOPSIS
    Advanced API coverage analysis script for PSImmich

.DESCRIPTION
    Analyzes PSImmich source code against OpenAPI specification to provide:
    - API endpoint coverage analysis
    - Parameter coverage validation
    - Folder organization validation against OpenAPI tags
    - Configurable exclusion of web-frontend specific APIs

.PARAMETER ApiSpecFile
    Path to the OpenAPI specification JSON file

.PARAMETER SourcePath
    Path to the source/Public directory containing PowerShell functions

.PARAMETER ExclusionConfigFile
    Path to JSON file containing API exclusions (optional)

.PARAMETER ShowParameters
    Include parameter analysis in the output

.PARAMETER ShowFolderMismatches
    Show functions that are in folders not matching their OpenAPI tag

.PARAMETER ExcludeSkipped
    Hide skipped APIs from console output (they will still be included in CSV exports)

.PARAMETER ExportResults
    Export results to CSV files.EXAMPLE
    .\Analyze-PSImmichAPI.ps1 -ApiSpecFile "api\api.2.2.0.json" -ShowParameters -ShowFolderMismatches -ExcludeSkipped
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ApiSpecFile = 'api\api.2.2.0.json',

    [string]$SourcePath = 'source\Public',

    [string]$ExclusionConfigFile,

    [switch]$ShowParameters,

    [switch]$ShowFolderMismatches,

    [switch]$ExcludeSkipped,

    [switch]$ExportResults
)

# Helper function to normalize folder names
function Get-NormalizedFolderName
{
    param([string]$TagName)

    $normalized = $TagName -replace '[^a-zA-Z0-9]', ''

    # Handle specific mappings
    $mappings = @{
        'Activities'         = 'Activity'
        'Albums'             = 'Album'
        'APIKeys'            = 'APIKey'
        'Assets'             = 'Asset'
        'Authadmin'          = 'Auth'
        'Authentication'     = 'Auth'
        'Download'           = 'Asset'  # Downloads are asset-related
        'Duplicates'         = 'Duplicates'
        'Faces'              = 'Face'
        'Jobs'               = 'Job'
        'Libraries'          = 'Library'
        'Map'                = 'Map'
        'Memories'           = 'Memories'
        'Notifications'      = 'Notification'
        'Notificationsadmin' = 'Notification'
        'OAuth'              = 'Auth'
        'Partners'           = 'Partner'
        'People'             = 'Person'
        'Search'             = 'Search'
        'Server'             = 'Server'
        'Sessions'           = 'Session'
        'SharedLinks'        = 'SharedLink'
        'Stacks'             = 'Stack'
        'Sync'               = 'Server'  # Sync operations are server-related
        'SystemConfig'       = 'ServerConfig'
        'SystemMetadata'     = 'Server'
        'Tags'               = 'Tag'
        'Timeline'           = 'Timeline'
        'Trash'              = 'Trash'
        'Users'              = 'User'
        'Usersadmin'         = 'User'
        'View'               = 'Asset'  # View operations are asset-related
    }

    return $mappings[$normalized] ?? $normalized
}

# Load API exclusions configuration
function Get-APIExclusions
{
    param([string]$ConfigFile)

    if ($ConfigFile -and (Test-Path $ConfigFile))
    {
        return Get-Content $ConfigFile | ConvertFrom-Json
    }

    # Default exclusions for web-frontend specific APIs
    return @{
        ExcludedPaths  = @(
            @{ Path = '/auth/admin-sign-up'; Method = 'POST'; Reason = 'Admin setup - not suitable for interactive use' }
            @{ Path = '/auth/change-password'; Method = 'POST'; Reason = 'Interactive web operation' }
            @{ Path = '/oauth/authorize'; Method = 'POST'; Reason = 'OIDC web flow - not for interactive use' }
            @{ Path = '/oauth/callback'; Method = 'POST'; Reason = 'OIDC web flow - not for interactive use' }
            @{ Path = '/oauth/link'; Method = 'POST'; Reason = 'OIDC web flow - not for interactive use' }
            @{ Path = '/oauth/mobile-redirect'; Method = 'GET'; Reason = 'Mobile app specific' }
            @{ Path = '/oauth/unlink'; Method = 'POST'; Reason = 'OIDC web flow - not for interactive use' }
            @{ Path = '/download/archive'; Method = 'POST'; Reason = 'Use Save-IMAsset instead' }
            @{ Path = '/download/asset/{id}'; Method = 'POST'; Reason = 'Use Save-IMAsset instead' }
            @{ Path = '/download/info'; Method = 'POST'; Reason = 'Web frontend specific' }
            @{ Path = '/assets/bulk-upload-check'; Method = 'POST'; Reason = 'Mobile app specific' }
            @{ Path = '/assets/exist'; Method = 'POST'; Reason = 'Bulk operation - unclear usage' }
            @{ Path = '/assets/stack/parent'; Method = 'PUT'; Reason = 'Unclear API usage' }
            @{ Path = '/assets/{id}/video/playback'; Method = 'GET'; Reason = 'Streaming - not applicable for PowerShell' }
            @{ Path = '/search/suggestions'; Method = 'GET'; Reason = 'Interactive search - not applicable for PowerShell' }
            @{ Path = '/tags'; Method = 'PUT'; Reason = 'Batch operation easily replicated in PowerShell' }
            @{ Path = '/tags/assets'; Method = 'PUT'; Reason = 'Batch operation easily replicated in PowerShell' }
            @{ Path = '/people/{id}'; Method = 'PUT'; Reason = 'Single item version of batch API' }
            @{ Path = '/people/{id}/reassign'; Method = 'PUT'; Reason = 'Unclear usage - no documentation' }
            @{ Path = '/reports/fix'; Method = 'POST'; Reason = 'Unclear usage - no documentation' }
            @{ Path = '/sync/delta-sync'; Method = 'POST'; Reason = 'Unclear usage - no documentation' }
            @{ Path = '/sync/full-sync'; Method = 'POST'; Reason = 'Unclear usage - no documentation' }
            @{ Path = '/system-metadata/admin-onboarding'; Method = 'GET'; Reason = 'Admin setup - web specific' }
            @{ Path = '/system-metadata/admin-onboarding'; Method = 'POST'; Reason = 'Admin setup - web specific' }
            @{ Path = '/system-metadata/reverse-geocoding-state'; Method = 'GET'; Reason = 'Internal state - unclear usage' }
        )
        ManualMappings = @(
            @{ Path = '/auth/login'; Method = 'POST'; CoveredBy = 'Connect-Immich' }
            @{ Path = '/auth/logout'; Method = 'POST'; CoveredBy = 'Disconnect-Immich' }
            @{ Path = '/assets'; Method = 'POST'; CoveredBy = 'Import-IMAsset' }
        )
    }
}

# Parse source code to find API calls
function Get-SourceCodeAPICalls
{
    param([string]$SourcePath)

    Write-Host 'Analyzing source code...' -ForegroundColor Cyan

    $AllFunctions = @()
    $AllCodeFiles = Get-ChildItem $SourcePath -Recurse -Filter '*.ps1'

    foreach ($file in $AllCodeFiles)
    {
        try
        {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $file.FullName,
                [ref]$null,
                [ref]$null
            )

            # Extract function name
            $functionDef = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $false) | Select-Object -First 1

            if (-not $functionDef)
            {
                continue
            }

            # Find InvokeImmichRestMethod calls
            $invokeCommands = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                    $args[0].GetCommandName() -eq 'InvokeImmichRestMethod'
                }, $true)

            foreach ($command in $invokeCommands)
            {
                $method = $null
                $relativePath = $null

                # Extract parameters by looking for -Method and -RelativePath
                for ($i = 0; $i -lt $command.CommandElements.Count; $i++)
                {
                    $element = $command.CommandElements[$i]
                    $elementText = if ($element.Value)
                    {
                        $element.Value
                    }
                    else
                    {
                        $element.Extent.Text
                    }

                    if ($elementText -eq '-Method' -and ($i + 1) -lt $command.CommandElements.Count)
                    {
                        $methodElement = $command.CommandElements[$i + 1]
                        $methodText = if ($methodElement.Value)
                        {
                            $methodElement.Value
                        }
                        else
                        {
                            $methodElement.Extent.Text
                        }
                        $method = $methodText -replace "['`"]", ''
                    }
                    elseif ($elementText -eq '-RelativePath' -and ($i + 1) -lt $command.CommandElements.Count)
                    {
                        $pathElement = $command.CommandElements[$i + 1]
                        $pathText = if ($pathElement.Value)
                        {
                            $pathElement.Value
                        }
                        else
                        {
                            $pathElement.Extent.Text
                        }
                        $relativePath = $pathText -replace "['`"]", ''
                    }
                }

                if ($method -and $relativePath)
                {
                    $AllFunctions += [PSCustomObject]@{
                        FunctionName = $functionDef.Name
                        Method       = $method.ToUpper()
                        RelativePath = $relativePath
                        FilePath     = $file.FullName
                        FolderName   = $file.Directory.Name
                        FileName     = $file.BaseName
                    }
                }
            }
        }
        catch
        {
            Write-Warning "Failed to parse $($file.FullName): $($_.Exception.Message)"
        }
    }

    return $AllFunctions
}

# Parse function parameters
function Get-FunctionParameters
{
    param([string]$FilePath)

    try
    {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $FilePath,
            [ref]$null,
            [ref]$null
        )

        $functionDef = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $false) | Select-Object -First 1

        if ($functionDef.Body.ParamBlock)
        {
            return $functionDef.Body.ParamBlock.Parameters | ForEach-Object {
                [PSCustomObject]@{
                    Name        = $_.Name.VariablePath.UserPath
                    Type        = $_.StaticType.Name
                    IsMandatory = $_.Attributes | Where-Object { $_.TypeName.Name -eq 'Parameter' } |
                        ForEach-Object { $_.NamedArguments | Where-Object { $_.ArgumentName -eq 'Mandatory' } |
                                ForEach-Object { $_.Argument.Value } }
                        }
                    }
                }
            }
            catch
            {
                Write-Warning "Failed to parse parameters for $FilePath`: $($_.Exception.Message)"
            }

            return @()
        }

        # Main analysis function
        function Invoke-APIAnalysis
        {
            param(
                [string]$ApiSpecFile,
                [string]$SourcePath,
                [object]$Exclusions,
                [switch]$ShowParameters,
                [switch]$ShowFolderMismatches
            )

            Write-Host 'Loading OpenAPI specification...' -ForegroundColor Cyan
            $apiSpec = Get-Content $ApiSpecFile | ConvertFrom-Json -Depth 10

            Write-Host 'Analyzing source code...' -ForegroundColor Cyan
            $sourceFunctions = Get-SourceCodeAPICalls -SourcePath $SourcePath

            Write-Host 'Processing API endpoints...' -ForegroundColor Cyan
            $results = @()

            foreach ($pathKey in $apiSpec.paths.PSObject.Properties.Name)
            {
                $pathObject = $apiSpec.paths.$pathKey

                foreach ($methodKey in $pathObject.PSObject.Properties.Name)
                {
                    $methodObject = $pathObject.$methodKey

                    # Skip if not a valid HTTP method
                    if ($methodKey -notin @('get', 'post', 'put', 'delete', 'patch'))
                    {
                        continue
                    }

                    $method = $methodKey.ToUpper()
                    $path = $pathKey

                    # Check if excluded
                    $exclusion = $Exclusions.ExcludedPaths | Where-Object {
                        $_.Path -eq $path -and $_.Method -eq $method
                    }

                    # Check manual mappings
                    $manualMapping = $Exclusions.ManualMappings | Where-Object {
                        $_.Path -eq $path -and $_.Method -eq $method
                    }

                    # Find matching source functions
                    $cleanPath = $path -replace '\{[^}]+\}', '*'
                    $matchingFunctions = $sourceFunctions | Where-Object {
                        $_.Method -eq $method -and $_.RelativePath -like $cleanPath
                    }

                    # Determine coverage
                    $covered = [bool]($matchingFunctions -or $manualMapping)
                    $skipped = [bool]$exclusion

                    $coveredBy = @()
                    if ($matchingFunctions)
                    {
                        $coveredBy += $matchingFunctions.FunctionName
                    }
                    if ($manualMapping)
                    {
                        $coveredBy += $manualMapping.CoveredBy
                    }

                    # Get OpenAPI tags and suggested folder
                    $tags = $methodObject.tags ?? @()
                    $suggestedFolder = if ($tags.Count -gt 0)
                    {
                        Get-NormalizedFolderName -TagName $tags[0]
                    }
                    else
                    {
                        'Unknown'
                    }

                    # Check folder placement
                    $actualFolders = $matchingFunctions.FolderName | Sort-Object -Unique
                    $folderMismatch = $actualFolders | Where-Object { $_ -ne $suggestedFolder }

                    # Determine combined status
                    $status = if ([bool]$methodObject.deprecated)
                    {
                        'Deprecated'
                    }
                    elseif ($skipped)
                    {
                        'Skipped'
                    }
                    elseif ($covered)
                    {
                        'Covered'
                    }
                    else
                    {
                        'Missing'
                    }

                    # Determine folder status
                    $folderStatus = if (-not $covered)
                    {
                        'N/A'
                    }
                    elseif (-not $folderMismatch)
                    {
                        'OK'
                    }
                    else
                    {
                        "Wrong Folder ($($actualFolders -join ', ') | $suggestedFolder)"
                    }

                    $result = [PSCustomObject]@{
                        Method          = $method
                        Path            = $path
                        Status          = $status
                        FolderStatus    = $folderStatus
                        CoveredBy       = ($coveredBy | Sort-Object -Unique) -join ', '
                        OperationId     = $methodObject.operationId
                        Tags            = ($tags -join ', ')
                        SuggestedFolder = $suggestedFolder
                        ActualFolders   = ($actualFolders -join ', ')
                        FolderMismatch  = [bool]$folderMismatch
                        Covered         = $covered
                        Skipped         = $skipped
                        Deprecated      = [bool]$methodObject.deprecated
                        SkipReason      = $exclusion.Reason
                        Description     = $methodObject.description
                        Parameters      = if ($ShowParameters -and $methodObject.parameters)
                        {
                            ($methodObject.parameters | ForEach-Object {
                                "$($_.name)($($_.required ? 'required' : 'optional'))"
                            }) -join ', '
                        }
                        else
                        {
                            ''
                        }
                    }

                    $results += $result
                }
            }

            return $results
        }

        # Color formatting for console output
        function Format-ResultsTable
        {
            param([object[]]$Results)


            return $Results | Format-Table 'Method', 'Path', 'Status', 'FolderStatus', 'CoveredBy' -AutoSize
        }

        # Main execution
        try
        {
            $scriptPath = $PSScriptRoot
            if (-not $scriptPath)
            {
                $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
            }

            $fullApiSpecPath = Join-Path $scriptPath $ApiSpecFile
            $fullSourcePath = Join-Path $scriptPath $SourcePath

            if (-not (Test-Path $fullApiSpecPath))
            {
                throw "API specification file not found: $fullApiSpecPath"
            }

            if (-not (Test-Path $fullSourcePath))
            {
                throw "Source path not found: $fullSourcePath"
            }

            # Load exclusions
            $exclusions = Get-APIExclusions -ConfigFile $ExclusionConfigFile

            # Run analysis
            $results = Invoke-APIAnalysis -ApiSpecFile $fullApiSpecPath -SourcePath $fullSourcePath -Exclusions $exclusions -ShowParameters:$ShowParameters -ShowFolderMismatches:$ShowFolderMismatches

            # Display results
            Write-Host "`n=== API Coverage Analysis ===" -ForegroundColor Yellow

            # Summary statistics
            $totalAPIs = $results.Count
            $coveredAPIs = ($results | Where-Object { $_.Covered -eq $true -and $_.Skipped -eq $false }).Count
            $skippedAPIs = ($results | Where-Object { $_.Skipped -eq $true }).Count
            $uncoveredAPIs = ($results | Where-Object { $_.Covered -eq $false -and $_.Skipped -eq $false }).Count
            $deprecatedAPIs = ($results | Where-Object { $_.Deprecated -eq $true }).Count

            $applicableAPIs = $coveredAPIs + $uncoveredAPIs
            $coveragePercentage = if ($applicableAPIs -gt 0)
            {
                [Math]::Round(($coveredAPIs / $applicableAPIs) * 100, 1)
            }
            else
            {
                0
            }

            Write-Host "Total APIs: $totalAPIs" -ForegroundColor White
            Write-Host "Covered: $coveredAPIs" -ForegroundColor Green
            Write-Host "Uncovered: $uncoveredAPIs" -ForegroundColor Red
            Write-Host "Skipped: $skippedAPIs" -ForegroundColor Gray
            Write-Host "Deprecated: $deprecatedAPIs" -ForegroundColor DarkYellow
            Write-Host "Coverage: $coveragePercentage% ($coveredAPIs/$applicableAPIs)" -ForegroundColor Magenta

            if ($ExcludeSkipped)
            {
                Write-Host 'Note: Skipped APIs are hidden from detailed results below' -ForegroundColor Cyan
            }

            # Show folder mismatches if requested
            if ($ShowFolderMismatches)
            {
                Write-Host "`n=== Folder Organization Issues ===" -ForegroundColor Yellow
                $mismatches = $results | Where-Object { $_.FolderMismatch -and $_.Covered }
                if ($mismatches)
                {
                    $mismatches | Format-Table Method, Path, SuggestedFolder, ActualFolders, CoveredBy -AutoSize
                }
                else
                {
                    Write-Host 'No folder mismatches found!' -ForegroundColor Green
                }
            }

            # Display main results
            Write-Host "`n=== Detailed Results ===" -ForegroundColor Yellow
            $displayResults = if ($ExcludeSkipped)
            {
                $results | Where-Object { $_.Status -ne 'Skipped' }
            }
            else
            {
                $results
            }
            Format-ResultsTable -Results $displayResults

            # Export if requested
            if ($ExportResults)
            {
                $exportPath = Join-Path $scriptPath "api-analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
                $results | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
                Write-Host "`nResults exported to: $exportPath" -ForegroundColor Green

                # Export uncovered APIs separately
                $uncoveredPath = Join-Path $scriptPath "api-uncovered-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
                $results | Where-Object { $_.Covered -eq $false -and $_.Skipped -eq $false } |
                    Export-Csv -Path $uncoveredPath -NoTypeInformation -Encoding UTF8
        Write-Host "Uncovered APIs exported to: $uncoveredPath" -ForegroundColor Yellow
    }
}
catch
{
    Write-Error "Analysis failed: $($_.Exception.Message)"
    exit 1
}
