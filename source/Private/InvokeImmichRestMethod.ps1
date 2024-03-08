<#PSScriptInfo
{
  "VERSION": "1.0.0",
  "GUID": "fd399995-5714-4944-b370-23b2b4dcd299",
  "FILENAME": "InvokeImmichRestMethod.ps1",
  "AUTHOR": "Hannes Palmquist",
  "CREATEDDATE": "2024-03-07",
  "COMPANYNAME": [],
  "COPYRIGHT": "(c) 2024, Hannes Palmquist, All Rights Reserved"
}
PSScriptInfo#>
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
        [hashtable]$Headers = @{}
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
                $InvokeRestMethodSplat.Authentication = 'Bearer'
                $InvokeRestMethodSplat.Token = $ImmichSession.JWT
            }
            'AccessToken'
            {
                $Headers.'X-API-Key' = (ConvertFrom-SecureString -SecureString $ImmichSession.AccessToken -AsPlainText)
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
    }
    elseif ($InvokeRestMethodSplat.Method -eq 'Post')
    {
        # Might need to be changed, some post requests require formdata
        $InvokeRestMethodSplat.Body = $Body | ConvertTo-Json -Compress
        $InvokeRestMethodSplat.ContentType = 'application/json'
    }


    Write-Debug -Message "InvokeImmichRestMethod; Calling Invoke-RestMethod with settings`r`n$($InvokeRestMethodSplat | ConvertTo-Json)"
    Invoke-RestMethod @InvokeRestMethodSplat -Verbose:$false | ForEach-Object { $_ }
}


#endregion
