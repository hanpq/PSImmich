function Import-IMAsset
{
    <#
    .DESCRIPTION
        Imports an Immich asset
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER FilePath
        Defines the path to the file to upload. Accepts pipeline input.
    .PARAMETER Duration
        Defines the duration if its a video asset
    .PARAMETER isArchived
        Defines if the new asset should be archived.
    .PARAMETER isFavorite
        Defines if the new asset should be a favorite
    .PARAMETER isOffline
        Defines if the new asset should be offline
    .PARAMETER isReadOnly
        Defines if the new asset should be read only
    .PARAMETER isVisible
        Defines if the new asset should be visible
    .PARAMETER libraryId
        Defines which library to upload the asset to
    .EXAMPLE
        Import-IMAsset -FilePath C:\file.jpg

        Uploads image to Immich
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP, retreived through PSBoundParameters')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [System.IO.FileInfo[]]
        $FilePath,

        [Parameter()]
        [ApiParameter('duration')]
        [string]
        $Duration,

        [Parameter()]
        [ApiParameter('isArchived')]
        [switch]
        $isArchived,

        [Parameter()]
        [ApiParameter('isFavorite')]
        [switch]
        $isFavorite ,

        [Parameter()]
        [ApiParameter('isOffline')]
        [switch]
        $isOffline ,

        [Parameter()]
        [ApiParameter('isReadOnly')]
        [switch]
        $isReadOnly,

        [Parameter()]
        [ApiParameter('isVisible')]
        [switch]
        $isVisible,

        [Parameter()]
        [ApiParameter('libraryId')]
        [string]
        $libraryId

    )

    process
    {
        $FilePath | ForEach-Object {
            $FileInfo = Get-Item -Path $PSItem.FullName
            $Uri = "$($ImmichSession.ApiUri)/assets"

            # Prepare form data
            $FormData = @{}
            $FormData += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
            $FormData += @{
                deviceAssetId  = $FileInfo.Name
                deviceId       = 'PSImmich'
                fileCreatedAt  = $FileInfo.CreationTime.ToString('yyyy-MM-ddTHH:mm:ss')
                fileModifiedAt = $FileInfo.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss')
            }

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
                    $MultipartContent.Add($StreamContent, 'assetData', $FileInfo.Name)

                    # Send request
                    $Response = $HttpClient.PostAsync($Uri, $MultipartContent).Result
                    $ResponseContent = $Response.Content.ReadAsStringAsync().Result

                    if ($Response.IsSuccessStatusCode)
                    {
                        $ResponseContent | ConvertFrom-Json | Get-IMAsset
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
                $Form = $FormData.Clone()
                $Form['assetData'] = $FileInfo

                $Result = Invoke-WebRequest -Uri $Uri -Method Post -Headers $Header -Form $Form -ContentType 'multipart/form-data'
                $Result.Content | ConvertFrom-Json | Get-IMAsset
            }
        }
    }
}
