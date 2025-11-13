#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Development utility to validate [ApiParameter] attributes against OpenAPI specification.

.DESCRIPTION
    This utility validates that PowerShell function parameters decorated with [ApiParameter]
    attributes correspond to actual parameters in the OpenAPI specification. This is a
    development tool for ensuring API parameter mappings are correct.

    Note: This may produce false positives during active development when:
    - API parameters use complex nested structures not directly mapped
    - Custom parameter handling is implemented
    - OpenAPI spec doesn't fully match implementation

.PARAMETER FunctionName
    Specific function name to validate. If not provided, validates all functions.

.PARAMETER Path
    Path to PSImmich source files. Defaults to current directory's source folder.

.PARAMETER OpenApiSpec
    Path to OpenAPI specification file. Defaults to api/api.2.2.0.json.

.EXAMPLE
    .\tools\Validate-ApiParameters.ps1

    Validates all functions with [ApiParameter] attributes.

.EXAMPLE
    .\tools\Validate-ApiParameters.ps1 -FunctionName "Set-IMUserPreference"

    Validates only the Set-IMUserPreference function.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$FunctionName,

    [Parameter()]
    [string]$Path = "source\Public",

    [Parameter()]
    [string]$OpenApiSpec = "api\api.2.2.0.json"
)

# Load OpenAPI specification
if (-not (Test-Path $OpenApiSpec)) {
    Write-Error "OpenAPI specification not found at: $OpenApiSpec"
    exit 1
}

Write-Host "Loading OpenAPI specification from: $OpenApiSpec" -ForegroundColor Green
$openApiDefinition = Get-Content $OpenApiSpec -Raw | ConvertFrom-Json

# Find PowerShell function files
$functionFiles = if ($FunctionName) {
    Get-ChildItem -Path $Path -Recurse -Filter "$FunctionName.ps1" -File
} else {
    Get-ChildItem -Path $Path -Recurse -Filter "*.ps1" -File
}

$validationResults = @()

foreach ($file in $functionFiles) {
    Write-Host "`nValidating: $($file.Name)" -ForegroundColor Cyan

    # Parse the PowerShell file
    $Content = Get-Content $file.FullName -Raw
    $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)
    $FunctionName = $file.Name -replace '\.ps1$'

    # Extract parameters with [ApiParameter] attributes
    $apiParameters = @()
    $parameterAsts = $AbstractSyntaxTree.FindAll({
        $args[0] -is [System.Management.Automation.Language.ParameterAst]
    }, $true)

    foreach ($paramAst in $parameterAsts) {
        # Look for ApiParameter attribute
        $apiParamAttr = $paramAst.Attributes | Where-Object {
            $_.TypeName.Name -eq 'ApiParameter' -or $_.TypeName.FullName -eq 'ApiParameter'
        }

        if ($apiParamAttr) {
            # Extract the API parameter name from the attribute
            $apiParamName = $null
            if ($apiParamAttr.PositionalArguments.Count -gt 0) {
                $apiParamName = $apiParamAttr.PositionalArguments[0].Value
            }

            $apiParameters += [PSCustomObject]@{
                PowerShellName = $paramAst.Name.VariablePath.UserPath
                ApiParameterName = $apiParamName
                ParameterAst = $paramAst
            }
        }
    }

    # Skip if no API parameters found
    if ($apiParameters.Count -eq 0) {
        Write-Host "  No [ApiParameter] attributes found" -ForegroundColor Yellow
        continue
    }

    Write-Host "  Found $($apiParameters.Count) [ApiParameter] attributes" -ForegroundColor Green

    # Find REST method calls
    $restMethodCalls = @()
    $invokeCommands = $AbstractSyntaxTree.FindAll({
        $args[0] -is [System.Management.Automation.Language.CommandAst] -and
        $args[0].GetCommandName() -eq 'InvokeImmichRestMethod'
    }, $true)

    foreach ($command in $invokeCommands) {
        $methodParam = $null
        $relativePathParam = $null

        # Parse command elements to find Method and RelativePath parameters
        for ($i = 0; $i -lt $command.CommandElements.Count; $i++) {
            $element = $command.CommandElements[$i]

            if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                if ($element.ParameterName -eq 'Method' -and ($i + 1) -lt $command.CommandElements.Count) {
                    $methodValue = $command.CommandElements[$i + 1]
                    if ($methodValue -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                        $methodParam = $methodValue.Value
                    }
                }
                elseif ($element.ParameterName -eq 'RelativePath' -and ($i + 1) -lt $command.CommandElements.Count) {
                    $relativePathValue = $command.CommandElements[$i + 1]
                    if ($relativePathValue -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                        $relativePathParam = $relativePathValue.Value
                    } elseif ($relativePathValue -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
                        $relativePathParam = $relativePathValue.Value
                    }
                }
            }
        }

        # Add to results if we found both method and path
        if ($methodParam -and $relativePathParam) {
            $restMethodCalls += [PSCustomObject]@{
                Method = $methodParam.ToUpper()
                RelativePath = $relativePathParam
            }
        }
    }

    # Find matching OpenAPI operations
    $matchingOperations = @()
    foreach ($RestCall in $restMethodCalls) {
        foreach ($Path in $openApiDefinition.paths.PSObject.Properties) {
            $isMatch = $false

            # Check for exact match first
            if ($RestCall.RelativePath -eq $Path.Name) {
                $isMatch = $true
            }
            # Check for pattern match (PowerShell variables vs OpenAPI parameters)
            elseif ($RestCall.RelativePath -match '\$\w+') {
                $pathPattern = [regex]::Escape($RestCall.RelativePath) -replace '\\\$\w+', '\{[^}]+\}'
                if ($Path.Name -match "^$pathPattern$") {
                    $isMatch = $true
                }
            }

            if ($isMatch) {
                $PathMethods = $Path.Value.PSObject.Properties | Where-Object { $_.Name -eq $RestCall.Method.ToLower() }
                if ($PathMethods) {
                    $matchingOperations += [PSCustomObject]@{
                        Path = $Path.Name
                        Method = $RestCall.Method
                        Operation = $PathMethods.Value
                    }
                }
            }
        }
    }

    Write-Host "  Found $($matchingOperations.Count) matching API operations" -ForegroundColor Green

    # Validate each API parameter
    foreach ($apiParam in $apiParameters) {
        $parameterFound = $false
        $foundInOperations = @()

        # Check if the API parameter exists in any of the matching operations
        foreach ($operation in $matchingOperations) {
            # Check request body parameters (for POST/PUT operations)
            if ($operation.Operation.requestBody -and
                $operation.Operation.requestBody.content -and
                $operation.Operation.requestBody.content.'application/json' -and
                $operation.Operation.requestBody.content.'application/json'.schema) {

                $schema = $operation.Operation.requestBody.content.'application/json'.schema

                # Handle direct properties (case-insensitive)
                if ($schema.properties -and ($schema.properties.PSObject.Properties.Name | ForEach-Object { $_.ToLower() }) -contains $apiParam.ApiParameterName.ToLower()) {
                    $parameterFound = $true
                    $foundInOperations += "$($operation.Method) $($operation.Path) (request body)"
                }

                # Handle schema references
                if ($schema.'$ref') {
                    # Resolve $ref to actual schema
                    $refPath = $schema.'$ref' -replace '^#/', '' -split '/'
                    $resolvedSchema = $openApiDefinition
                    foreach ($pathSegment in $refPath) {
                        $resolvedSchema = $resolvedSchema.$pathSegment
                    }

                    # Check properties in resolved schema (case-insensitive)
                    if ($resolvedSchema.properties -and ($resolvedSchema.properties.PSObject.Properties.Name | ForEach-Object { $_.ToLower() }) -contains $apiParam.ApiParameterName.ToLower()) {
                        $parameterFound = $true
                        $foundInOperations += "$($operation.Method) $($operation.Path) (request body - resolved)"
                    }
                }
            }

            # Check query parameters (case-insensitive)
            if ($operation.Operation.parameters) {
                $queryParam = $operation.Operation.parameters | Where-Object {
                    $_.name.ToLower() -eq $apiParam.ApiParameterName.ToLower() -and $_.in -eq 'query'
                }
                if ($queryParam) {
                    $parameterFound = $true
                    $foundInOperations += "$($operation.Method) $($operation.Path) (query parameter)"
                }
            }

            # Check path parameters (case-insensitive)
            if ($operation.Operation.parameters) {
                $pathParam = $operation.Operation.parameters | Where-Object {
                    $_.name.ToLower() -eq $apiParam.ApiParameterName.ToLower() -and $_.in -eq 'path'
                }
                if ($pathParam) {
                    $parameterFound = $true
                    $foundInOperations += "$($operation.Method) $($operation.Path) (path parameter)"
                }
            }
        }

        # Record validation result
        $result = [PSCustomObject]@{
            FunctionName = $FunctionName
            PowerShellParameter = $apiParam.PowerShellName
            ApiParameter = $apiParam.ApiParameterName
            Found = $parameterFound
            FoundInOperations = $foundInOperations -join '; '
            TotalOperations = $matchingOperations.Count
        }

        $validationResults += $result

        # Display result
        if ($parameterFound) {
            Write-Host "    ✓ $($apiParam.PowerShellName) -> $($apiParam.ApiParameterName)" -ForegroundColor Green
            if ($foundInOperations.Count -gt 0) {
                Write-Host "      Found in: $($foundInOperations -join '; ')" -ForegroundColor DarkGreen
            }
        } else {
            Write-Host "    ✗ $($apiParam.PowerShellName) -> $($apiParam.ApiParameterName)" -ForegroundColor Red
            if ($matchingOperations.Count -gt 0) {
                Write-Host "      Not found in any of $($matchingOperations.Count) matching operations" -ForegroundColor DarkRed
            } else {
                Write-Host "      No matching API operations found for this function" -ForegroundColor Yellow
            }
        }
    }
}

# Summary
Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "="*80 -ForegroundColor Cyan

$totalParameters = $validationResults.Count
$validParameters = ($validationResults | Where-Object { $_.Found }).Count
$invalidParameters = $totalParameters - $validParameters

Write-Host "Total Parameters Validated: $totalParameters" -ForegroundColor White
Write-Host "Valid Parameters: $validParameters" -ForegroundColor Green
Write-Host "Invalid Parameters: $invalidParameters" -ForegroundColor Red

if ($invalidParameters -gt 0) {
    Write-Host "`nINVALID PARAMETERS:" -ForegroundColor Red
    $validationResults | Where-Object { -not $_.Found } | ForEach-Object {
        Write-Host "  $($_.FunctionName): $($_.PowerShellParameter) -> $($_.ApiParameter)" -ForegroundColor Red
    }
}

# Export results for further analysis if needed
$outputFile = "ApiParameterValidation_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$validationResults | Export-Csv -Path $outputFile -NoTypeInformation
Write-Host "`nDetailed results exported to: $outputFile" -ForegroundColor Yellow

# Exit with appropriate code
if ($invalidParameters -eq 0) {
    Write-Host "`n✓ All API parameters validated successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n✗ Some API parameters failed validation. Check results above." -ForegroundColor Red
    exit 1
}
