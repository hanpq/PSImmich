function ConvertTo-ApiParameters
{
    <#
    .DESCRIPTION
        Converts PowerShell cmdlet bound parameters to API parameter format using ApiParameter attributes.
        Supports dot-notation for nested parameter structures (e.g., 'avatar.color', 'transport.host').
    .PARAMETER BoundParameters
        The $PSBoundParameters from the calling cmdlet
    .PARAMETER CmdletName
        The name of the calling cmdlet (used for caching reflection data)
    .EXAMPLE
        # Simple parameters
        [ApiParameter('name')] $UserName -> { "name": "value" }

        # Nested parameters using dot-notation
        [ApiParameter('avatar.color')] $AvatarColor -> { "avatar": { "color": "value" } }
        [ApiParameter('transport.host')] $SmtpHost -> { "transport": { "host": "value" } }

        $Body = ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Ignored, internal function')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory)]
        $BoundParameters,

        [Parameter(Mandatory)]
        [string]$CmdletName
    )

    # Cache parameter mappings to avoid repeated reflection
    if (-not $script:ApiParameterMappings)
    {
        $script:ApiParameterMappings = @{}
    }

    if (-not $script:ApiParameterMappings.ContainsKey($CmdletName))
    {
        Write-Debug "Building API parameter mapping for $CmdletName"

        $cmd = Get-Command $CmdletName -ErrorAction SilentlyContinue
        if (-not $cmd)
        {
            Write-Warning "Could not find command $CmdletName for parameter mapping"
            return @{}
        }

        $mapping = @{}

        foreach ($paramName in $cmd.Parameters.Keys)
        {
            # Skip common parameters that shouldn't be passed to API
            if ($paramName -in @('Session', 'Verbose', 'Debug', 'ErrorAction', 'ErrorVariable', 'WarningAction', 'WarningVariable', 'InformationAction', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'Confirm', 'WhatIf'))
            {
                continue
            }

            $paramInfo = $cmd.Parameters[$paramName]

            # Look for ApiParameter attribute
            $apiAttr = $paramInfo.Attributes | Where-Object { $_.GetType().Name -eq 'ApiParameterAttribute' }

            if ($apiAttr)
            {
                # Use explicit API parameter name from attribute
                $mapping[$paramName] = $apiAttr.Name
                Write-Debug "Parameter $paramName maps to API parameter: $($apiAttr.Name)"
            }
            # Only process parameters with [ApiParameter] attribute - skip others
        }

        $script:ApiParameterMappings[$CmdletName] = $mapping
    }

    # Convert bound parameters using the cached mapping
    $apiParams = @{}
    $mapping = $script:ApiParameterMappings[$CmdletName]

    foreach ($param in $BoundParameters.GetEnumerator())
    {
        if ($mapping.ContainsKey($param.Key))
        {
            $apiParamName = $mapping[$param.Key]

            # Handle dot-notation for nested parameters
            if ($apiParamName -like '*.*')
            {
                # Split the parameter name by dots to create nested structure
                $parts = $apiParamName -split '\.'
                $currentLevel = $apiParams

                # Navigate/create nested structure for all parts except the last
                for ($i = 0; $i -lt $parts.Count - 1; $i++)
                {
                    $part = $parts[$i]
                    if (-not $currentLevel.ContainsKey($part))
                    {
                        $currentLevel[$part] = @{}
                    }
                    $currentLevel = $currentLevel[$part]
                }

                # Set the final value at the deepest level
                $finalKey = $parts[-1]
                $currentLevel[$finalKey] = $param.Value
                Write-Debug "Converting nested parameter: $($param.Key) -> $apiParamName = $($param.Value)"
            }
            else
            {
                # Handle simple (non-nested) parameters
                $apiParams[$apiParamName] = $param.Value
                Write-Debug "Converting parameter: $($param.Key) -> $apiParamName = $($param.Value)"
            }
        }
    }

    return $apiParams
}
