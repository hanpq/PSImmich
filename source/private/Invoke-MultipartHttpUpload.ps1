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
        [string]$FileFieldName
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

        # Add form fields
        foreach ($field in $FormData.GetEnumerator())
        {
            $StringContent = New-Object System.Net.Http.StringContent($field.Value.ToString())
            $MultipartContent.Add($StringContent, $field.Key)
        }

        # Add file content
        $FileStream = [System.IO.File]::OpenRead($FileInfo.FullName)
        $StreamContent = New-Object System.Net.Http.StreamContent($FileStream)
        $StreamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue('application/octet-stream')
        $MultipartContent.Add($StreamContent, $FileFieldName, $FileInfo.Name)

        # Send request
        $Response = $HttpClient.PostAsync($(($Session.ApiUri) + $RelativePath), $MultipartContent).Result
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
