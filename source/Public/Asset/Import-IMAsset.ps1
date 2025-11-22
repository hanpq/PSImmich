function Import-IMAsset
{
    <#
    .SYNOPSIS
        Imports media files as Immich assets
    .DESCRIPTION
        Uploads media files (photos and videos) to Immich, creating new assets. Uses unified HttpClient
        implementation for reliable cross-platform multipart uploads with metadata and status options.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER FilePath
        The path(s) to the media file(s) to upload. Accepts pipeline input and multiple files.
    .PARAMETER Duration
        The duration for video assets, if applicable.
    .PARAMETER IsArchived
        Specifies whether the imported asset should be archived upon upload.
    .PARAMETER IsFavorite
        Specifies whether the imported asset should be marked as a favorite.
    .PARAMETER IsOffline
        Specifies whether the imported asset should be marked as offline.
    .PARAMETER IsReadOnly
        Specifies whether the imported asset should be marked as read-only.
    .PARAMETER IsVisible
        Specifies whether the imported asset should be visible in the timeline.
    .PARAMETER LibraryId
        The UUID of the library to upload the asset to. If not specified, uses the default library.
    .EXAMPLE
        Import-IMAsset -FilePath 'C:\Photos\vacation.jpg'

        Imports a single photo to Immich.
    .EXAMPLE
        Get-ChildItem '*.jpg' | Import-IMAsset -IsFavorite

        Imports all JPG files in the current directory and marks them as favorites.
    .EXAMPLE
        Import-IMAsset -FilePath 'C:\Videos\movie.mp4' -Duration '00:02:30' -LibraryId 'library-uuid'

        Imports a video with specified duration to a specific library.
    .EXAMPLE
        @('photo1.jpg', 'photo2.jpg') | Import-IMAsset -IsArchived:$true

        Imports multiple photos and archives them immediately.
    .NOTES
        Uses System.Net.Http.HttpClient for reliable multipart uploads across all PowerShell editions.
        This cmdlet supports ShouldProcess and will prompt for confirmation before uploading files.
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
            $RelativePath = '/assets'

            # Prepare form data
            $FormData = @{}
            $FormData += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
            $FormData += @{
                deviceAssetId  = $FileInfo.Name
                deviceId       = 'PSImmich'
                fileCreatedAt  = $FileInfo.CreationTime.ToString('yyyy-MM-ddTHH:mm:ss')
                fileModifiedAt = $FileInfo.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss')
            }

            # Use unified HttpClient approach via private function
            $ResponseContent = Invoke-MultipartHttpUpload -RelativePath $RelativePath -Session:$Session -FormData $FormData -FileInfo $FileInfo -FileFieldName 'assetData'

            $ResponseContent | ConvertFrom-Json | Get-IMAsset
        }
    }
}
