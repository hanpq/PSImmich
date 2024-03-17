function InvokeImmichRestMethod
{
    <#
    .DESCRIPTION
        Function that is responsible for making the rest api web call
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
         Defines QueryParameters for the REST API call
    .PARAMETER ContentType
        Defines the contenttype for the request
    .PARAMETER OutFilePath
        Defines an output directory
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
        $NewBody = @{}
        foreach ($Key in $Body.Keys)
        {
            switch ($Body.$Key.GetType().Name)
            {
                'boolean'
                {
                    $NewBody.$Key = $Body.$Key.ToString().ToLower()
                    break
                }
                'SwitchParameter'
                {
                    $NewBody.$Key = ($Body.$Key -as [boolean]).ToString().ToLower()
                    break
                }
                'datetime'
                {
                    $NewBody.$Key = $Body.$Key.ToString('yyyy-MM-ddTHH:mm:ss')
                    break
                }
                default
                {
                    $NewBody.$Key = $Body.$Key
                }
            }
        }
        $InvokeRestMethodSplat.Body = $NewBody | ConvertTo-Json -Compress
    }

    # Add query parameters to invoke rest method splat
    if ($QueryParameters)
    {
        $InvokeRestMethodSplat.Uri += '?'
        $QueryParameterStringArray = foreach ($QueryParameter in $QueryParameters.Keys)
        {
            switch ($QueryParameters.$QueryParameter.GetType().Name)
            {
                'string'
                {
                    "$($QueryParameter)=$($QueryParameters.$QueryParameter)"
                }
                'boolean'
                {
                    "$($QueryParameter)=$($QueryParameters.$QueryParameter.ToString().ToLower())"
                }
                'SwitchParameter'
                {
                    "$($QueryParameter)=$(($QueryParameters.$QueryParameter -as [boolean]).ToString().ToLower())"
                }
                'int32'
                {
                    "$($QueryParameter)=$($QueryParameters.$QueryParameter)"
                }
                'datetime'
                {
                    "$($QueryParameter)=$($QueryParameters.$QueryParameter.ToString('yyyy-MM-ddTHH:mm:ss'))"
                }
                default
                {
                    Write-Warning -Message "Unknown type of queryparameter $QueryParameter : $($QueryParameters.$QueryParameter.GetType().Name)"
                }
            }
        }
        $InvokeRestMethodSplat.Uri += [URI]::EscapeUriString(($QueryParameterStringArray -join '&'))
    }

    # Skip token validation on auth/login calls because the token is not retreived at that point
    if ($InvokeRestMethodSplat.Uri -notlike '*auth/login*')
    {
        $ImmichSession.ValidateToken()
    }

    Write-Debug -Message "InvokeImmichRestMethod; Calling Invoke-RestMethod with settings`r`n$($InvokeRestMethodSplat | ConvertTo-Json)"

    # Output response to file if content type is octet-stream
    if ($ContentType -eq 'application/octet-stream' -and $Method -eq 'Get')
    {
        Invoke-RestMethod @InvokeRestMethodSplat -Verbose:$false -OutFile $OutFilePath
    }
    else
    {
        Invoke-RestMethod @InvokeRestMethodSplat -Verbose:$false | ForEach-Object { $_ }
    }

}


#endregion
