﻿function Import-IMAsset
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
        [string]
        $Duration,

        [Parameter()]
        [switch]
        $isArchived,

        [Parameter()]
        [switch]
        $isFavorite ,

        [Parameter()]
        [switch]
        $isOffline ,

        [Parameter()]
        [switch]
        $isReadOnly,

        [Parameter()]
        [switch]
        $isVisible,

        [Parameter()]
        [string]
        $libraryId

    )

    BEGIN
    {
        # Do not run on Windows Powershell
        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            Write-Warning -Message 'Import-IMAsset is not currently supported on Windows Powershell, please use Powershell Core instead.'
            break
        }
    }

    PROCESS
    {
        $FilePath | ForEach-Object {
            $FileInfo = Get-Item -Path $PSItem.FullName
            $Uri = "$($ImmichSession.ApiUri)/assets"
            $Header = @{
                'Accept'    = 'application/json'
                'x-api-key' = ConvertFromSecureString -SecureString $ImmichSession.AccessToken
            }
            $Form = @{}
            $Form += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'Duration', 'isArchived', 'isFavorite', 'isOffline', 'isReadOnly', 'isVisible', 'libraryId')
            $Form += @{
                deviceAssetId  = $FileInfo.Name
                deviceId       = 'PSImmich'
                fileCreatedAt  = $FileInfo.CreationTime.ToString('yyyy-MM-ddTHH:mm:ss')
                fileModifiedAt = $FileInfo.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss')
                assetData      = $FileInfo
            }
            $Result = Invoke-WebRequest -Uri $Uri -Method Post -Headers $Header -Form $Form -ContentType 'multipart/form-data'
            $Result.Content | ConvertFrom-Json | Get-IMAsset
        }
    }
}
