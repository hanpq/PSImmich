function Add-IMMyProfilePicture
{
    <#
    .DESCRIPTION
        Adds an Immich user profile picture
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER FilePath
        Defines the image file path for the profile picture. Supports common image formats (JPG, PNG, GIF).
    .EXAMPLE
        Add-IMMyProfilePicture -FilePath C:\avatar.jpg

        Add profile picture to current user
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP, retreived through PSBoundParameters')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $FilePath
    )

    process
    {
        $FileInfo = Get-Item -Path $FilePath.FullName
        $Uri = "$($ImmichSession.ApiUri)/users/profile-image"

        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            # Windows PowerShell - use HttpClient
            Add-Type -AssemblyName System.Net.Http
            $HttpClient = New-Object System.Net.Http.HttpClient
            $MultipartContent = New-Object System.Net.Http.MultipartFormDataContent

            try
            {
                # Add API key header
                $HttpClient.DefaultRequestHeaders.Add('x-api-key', (ConvertFromSecureString -SecureString $ImmichSession.AccessToken))

                # Add file content
                $FileStream = [System.IO.File]::OpenRead($FileInfo.FullName)
                $StreamContent = New-Object System.Net.Http.StreamContent($FileStream)
                $StreamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue('application/octet-stream')
                $MultipartContent.Add($StreamContent, 'file', $FileInfo.Name)

                # Send request
                $Response = $HttpClient.PostAsync($Uri, $MultipartContent).Result
                $ResponseContent = $Response.Content.ReadAsStringAsync().Result

                if ($Response.IsSuccessStatusCode)
                {
                    $ResponseContent | ConvertFrom-Json
                }
                else
                {
                    throw "HTTP $($Response.StatusCode): $ResponseContent"
                }
            }
            finally
            {
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
        else
        {
            # PowerShell Core - use Invoke-WebRequest
            $Header = @{
                'Accept'    = 'application/json'
                'x-api-key' = ConvertFromSecureString -SecureString $ImmichSession.AccessToken
            }
            $Form = @{
                file = $FileInfo
            }

            $Result = Invoke-WebRequest -Uri $Uri -Method Post -Headers $Header -Form $Form -ContentType 'multipart/form-data'
            $Result.Content | ConvertFrom-Json
        }
    }
}
