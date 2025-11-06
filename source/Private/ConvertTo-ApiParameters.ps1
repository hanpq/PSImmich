function ConvertTo-ApiParameters
{
    <#
    .DESCRIPTION
        Converts PowerShell cmdlet bound parameters to API parameter format using ApiParameter attributes or camelCase convention
    .PARAMETER BoundParameters
        The $PSBoundParameters from the calling cmdlet
    .PARAMETER CmdletName
        The name of the calling cmdlet (used for caching reflection data)
    .EXAMPLE
        $Body = ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    #>
    [CmdletBinding()]
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
            else
            {
                # Default to camelCase conversion
                $apiName = $paramName.Substring(0, 1).ToLower() + $paramName.Substring(1)
                $mapping[$paramName] = $apiName
                Write-Debug "Parameter $paramName maps to API parameter: $apiName (camelCase)"
            }
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
            $apiParams[$apiParamName] = $param.Value
            Write-Debug "Converting parameter: $($param.Key) -> $apiParamName = $($param.Value)"
        }
    }

    return $apiParams
}
