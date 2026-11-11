function InvokeImmichRestMethod
{
    <#
    .DESCRIPTION
        Function that is responsible for making the rest api web call
        Debug output omits request values to avoid exposing credentials.
    .PARAMETER NoAuth
        Specifies that the REST API call do not need authentication
    .PARAMETER Method
        Defines the method to use when calling the REST API, valid values GET,POST etc.
    .PARAMETER ImmichSession
        A ImmichSession object to use for the call.
    .PARAMETER RelativePath
        The REST API path relative to the base URL
    .PARAMETER Body
        Defines body attributes for the REST API call
    .PARAMETER Headers
        Defines header attributes for the REST API call
    .PARAMETER QueryParameters
        Defines query parameters. Keys and values are percent-encoded individually;
        array values use repeated bracketed keys.
    .PARAMETER ContentType
        Defines the contenttype for the request
    .PARAMETER OutFilePath
        Defines an output directory
    .PARAMETER RawBody
        Provides a raw body to use instead of parsing a hashtable to json.
    .EXAMPLE
        InvokeImmichRestMethod
    #>
    [CmdletBinding()] # Enabled advanced function support
    param(
        [switch]$NoAuth,
        [string]$Method,
        [immichsession]$ImmichSession,
        [string]$RelativePath,
        [hashtable]$Body,
        [string]$RawBody,
        [hashtable]$Headers,
        [hashtable]$QueryParameters,
        [string]$ContentType = 'application/json',
        [System.IO.FileInfo]$OutFilePath
    )

    # Use immich session from parameter first, from module scope session second and throw if none is found
    if (-not $ImmichSession)
    {
        Write-Debug -Message 'InvokeImmichRestMethod; No ImmichSession passed as parameter'
        if ($script:ImmichSession)
        {
            Write-Debug -Message 'InvokeImmichRestMethod; ImmichSession found in script scope'
            $ImmichSession = $script:ImmichSession
        }
        else
        {
            Write-Error -Message 'No Immich Session established, please call Connect-Immich' -ErrorAction Stop
        }
    }

    # Initialize invoke rest method splat
    $InvokeRestMethodSplat = @{
        Method      = $Method
        Uri         = "$($ImmichSession.ApiUri)$($RelativePath)"
        ContentType = $ContentType
    }

    # Skip auth headers if noauth is specified
    if (-not $NoAuth)
    {
        # Custom headers has not been provided so we need to initialize an empty hashtable
        if (-not $Headers)
        {
            $Headers = @{}
        }
        switch ($ImmichSession.AuthMethod)
        {
            'Credential'
            {
                $Headers.Authorization = "Bearer $(ConvertFromSecureString -SecureString $ImmichSession.JWT)"
            }
            'AccessToken'
            {
                $Headers.'X-API-Key' = ConvertFromSecureString -SecureString $ImmichSession.AccessToken
            }
        }
    }

    # Add headers to invoke rest method splat
    if ($Headers)
    {
        $InvokeRestMethodSplat.Headers = $Headers
    }

    # Add body to invoke rest method splat
    if ($Body)
    {
        $NewBody = ConvertTo-ImmichRequestBody -InputObject $Body
        $InvokeRestMethodSplat.Body = $NewBody | ConvertTo-Json -Compress -Depth 10
    }

    if ($RawBody)
    {
        $InvokeRestMethodSplat.Body = $RawBody
    }

    # Add query parameters to invoke rest method splat
    if ($QueryParameters)
    {
        $InvokeRestMethodSplat.Uri += '?'
        $QueryParameterStringArray = foreach ($QueryParameter in $QueryParameters.Keys)
        {
            $EncodedKey = [uri]::EscapeDataString($QueryParameter)
            # Arrays are sent as bracketed keys, e.g. status[]=a&status[]=b. A single repeated-key value
            # is parsed as a string by the server, which rejects it for array-typed parameters.
            if ($QueryParameters.$QueryParameter -is [System.Collections.IEnumerable] -and $QueryParameters.$QueryParameter -isnot [string])
            {
                foreach ($Item in $QueryParameters.$QueryParameter)
                {
                    $EncodedKey + '[]=' + [uri]::EscapeDataString([string]$Item)
                }
                continue
            }

            $QueryValue = switch ($QueryParameters.$QueryParameter.GetType().Name)
            {
                'string'
                {
                    [string]$QueryParameters.$QueryParameter
                }
                'boolean'
                {
                    $QueryParameters.$QueryParameter.ToString().ToLowerInvariant()
                }
                'SwitchParameter'
                {
                    ([bool]$QueryParameters.$QueryParameter).ToString().ToLowerInvariant()
                }
                'int32'
                {
                    $QueryParameters.$QueryParameter.ToString([Globalization.CultureInfo]::InvariantCulture)
                }
                'double'
                {
                    $QueryParameters.$QueryParameter.ToString([Globalization.CultureInfo]::InvariantCulture)
                }
                'datetime'
                {
                    ([DateTimeOffset]$QueryParameters.$QueryParameter).UtcDateTime.ToString('o')
                }
                default
                {
                    Write-Warning -Message "Unknown type of queryparameter $QueryParameter : $($QueryParameters.$QueryParameter.GetType().Name)"
                }
            }
            if ($null -ne $QueryValue)
            {
                $EncodedKey + '=' + [uri]::EscapeDataString($QueryValue)
            }
        }
        $InvokeRestMethodSplat.Uri += $QueryParameterStringArray -join '&'
    }

    # Skip token validation on auth/login calls because the token is not retreived at that point
    if ($InvokeRestMethodSplat.Uri -notlike '*auth/login*')
    {
        $ImmichSession.ValidateToken()
    }

    Write-Debug -Message 'InvokeImmichRestMethod; Calling Invoke-RestMethod'

    # Write the response to the requested file when an output path is supplied
    if ($OutFilePath)
    {
        Invoke-RestMethod @InvokeRestMethodSplat -Verbose:$false -OutFile $OutFilePath
    }
    else
    {
        Invoke-RestMethod @InvokeRestMethodSplat -Verbose:$false | ForEach-Object { if ($_ -ne '' -and $null -ne $_)
            {
                $_
            } }
    }

}


#endregion
