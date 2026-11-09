function Invoke-MultipartHttpUpload
{
    <#
    .SYNOPSIS
        Performs multipart HTTP upload using System.Net.Http.HttpClient
    .DESCRIPTION
        Handles multipart form data uploads with file content using .NET HttpClient.
        Centralizes HttpClient logic for consistent cross-platform file uploads.
    .PARAMETER RelativePath
        The relative path for the API endpoint (e.g., '/assets', '/users/profile-image')
    .PARAMETER Session
        The ImmichSession object containing API URI and access token
    .PARAMETER FormData
        Hashtable containing form fields to include in the multipart request
    .PARAMETER FileInfo
        FileInfo object representing the file to upload
    .PARAMETER FileFieldName
        The form field name for the file (e.g., 'assetData', 'file')
    .PARAMETER Headers
        Additional HTTP headers to send with the request (e.g., 'x-immich-checksum')
    .PARAMETER AdditionalFiles
        Hashtable of extra form field names to FileInfo objects, sent as application/octet-stream parts
    .PARAMETER QueryParameters
        Hashtable of query string parameters appended to the request URI. Booleans are lowercased.
    .EXAMPLE
        Invoke-MultipartHttpUpload -RelativePath '/assets' -Session $session -FormData $data -FileInfo $file -FileFieldName 'assetData'
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session,

        [Parameter(Mandatory)]
        [string]$RelativePath,

        [Parameter()]
        [hashtable]$FormData = @{},

        [Parameter(Mandatory)]
        [object]$FileInfo,

        [Parameter(Mandatory)]
        [string]$FileFieldName,

        [Parameter()]
        [hashtable]$Headers = @{},

        [Parameter()]
        [hashtable]$AdditionalFiles = @{},

        [Parameter()]
        [hashtable]$QueryParameters = @{}
    )


    if (-not $Session)
    {
        Write-Debug -Message 'Invoke-MultiPathHttpUpload; No ImmichSession passed as parameter'
        if ($script:ImmichSession)
        {
            Write-Debug -Message 'Invoke-MultiPathHttpUpload; ImmichSession found in script scope'
            $Session = $script:ImmichSession
        }
        else
        {
            Write-Error -Message 'No Immich Session established, please call Connect-Immich' -ErrorAction Stop
        }
    }

    # Initialize HttpClient components
    Add-Type -AssemblyName System.Net.Http
    $HttpClient = New-Object System.Net.Http.HttpClient
    $MultipartContent = New-Object System.Net.Http.MultipartFormDataContent
    $FileStream = $null
    $OpenStreams = @()

    try
    {
        # Validate FileInfo object has required properties
        if (-not $FileInfo.FullName -or -not $FileInfo.Name)
        {
            throw 'FileInfo object must have FullName and Name properties'
        }

        # Add API key header
        $ApiKey = ConvertFromSecureString -SecureString $Session.AccessToken
        $HttpClient.DefaultRequestHeaders.Add('x-api-key', $ApiKey)

        foreach ($header in $Headers.GetEnumerator())
        {
            $HttpClient.DefaultRequestHeaders.Add($header.Key, [string]$header.Value)
        }

        # Add form fields
        foreach ($field in $FormData.GetEnumerator())
        {
            $StringContent = New-Object System.Net.Http.StringContent((ConvertTo-MultipartFieldValue -Value $field.Value))
            $MultipartContent.Add($StringContent, $field.Key)
        }

        # Add file content
        $FileStream = [System.IO.File]::OpenRead($FileInfo.FullName)
        $StreamContent = New-Object System.Net.Http.StreamContent($FileStream)
        $StreamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue('application/octet-stream')
        $MultipartContent.Add($StreamContent, $FileFieldName, $FileInfo.Name)

        foreach ($additionalFile in $AdditionalFiles.GetEnumerator())
        {
            $AdditionalStream = [System.IO.File]::OpenRead($additionalFile.Value.FullName)
            $OpenStreams += $AdditionalStream
            $AdditionalContent = New-Object System.Net.Http.StreamContent($AdditionalStream)
            $AdditionalContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue('application/octet-stream')
            $MultipartContent.Add($AdditionalContent, $additionalFile.Key, $additionalFile.Value.Name)
        }

        # Send request
        $Uri = ($Session.ApiUri) + $RelativePath
        if ($QueryParameters.Count -gt 0)
        {
            $QueryPairs = foreach ($Query in $QueryParameters.GetEnumerator())
            {
                $QueryValue = $Query.Value
                if ($QueryValue -is [bool])
                {
                    $QueryValue = $QueryValue.ToString().ToLowerInvariant()
                }
                [uri]::EscapeDataString($Query.Key) + '=' + [uri]::EscapeDataString([string]$QueryValue)
            }
            $Uri += '?' + ($QueryPairs -join '&')
        }
        $Response = $HttpClient.PostAsync($Uri, $MultipartContent).Result
        $ResponseContent = $Response.Content.ReadAsStringAsync().Result

        if ($Response.IsSuccessStatusCode)
        {
            return $ResponseContent
        }
        else
        {
            throw "HTTP $($Response.StatusCode): $ResponseContent"
        }
    }
    finally
    {
        # Dispose of resources in proper order
        if ($FileStream)
        {
            $FileStream.Dispose()
        }
        foreach ($Stream in $OpenStreams)
        {
            $Stream.Dispose()
        }
        if ($MultipartContent)
        {
            $MultipartContent.Dispose()
        }
        if ($HttpClient)
        {
            $HttpClient.Dispose()
        }
    }
}
