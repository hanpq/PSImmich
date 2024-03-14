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
        [hashtable]$Body = @{},
        [hashtable]$Headers = @{},
        [hashtable]$QueryParameters = @{},
        [string]$ContentType = 'application/json',
        [System.IO.FileInfo]$OutFilePath
    )

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
            Write-Error -Message 'No Immich Session established, please call Connect-Immich'
        }
    }

    $InvokeRestMethodSplat = @{
        Method = $Method
        Uri    = "$($ImmichSession.ApiUri)$($RelativePath)"
    }

    if (-not $NoAuth)
    {
        switch ($ImmichSession.AuthMethod)
        {
            'Credential'
            {
                $Headers.Authorization = "Bearer $($ImmichSession.JWT)"
            }
            'AccessToken'
            {
                $Headers.'X-API-Key' = ConvertFromSecureString -SecureString $ImmichSession.AccessToken
            }
        }
    }

    if ($Headers.Keys.Count -gt 0)
    {
        $InvokeRestMethodSplat.Headers = $Headers
    }
    if ($InvokeRestMethodSplat.Method -eq 'Get')
    {
        if ($Body.Keys.Count -gt 0 )
        {
            $InvokeRestMethodSplat.Body = $Body
        }
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
    }
    elseif (@('Post', 'Put', 'Delete', 'Patch') -contains $InvokeRestMethodSplat.Method)
    {
        # Might need to be changed, some post requests require formdata
        $InvokeRestMethodSplat.Body = $Body | ConvertTo-Json -Compress
        $InvokeRestMethodSplat.ContentType = $ContentType
    }
    else
    {
        Write-Error -Message "Unknown method: $($InvokeRestMethodSplat.Method), unable to perform api call" -ErrorAction Stop
    }


    Write-Debug -Message "InvokeImmichRestMethod; Calling Invoke-RestMethod with settings`r`n$($InvokeRestMethodSplat | ConvertTo-Json)"

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
