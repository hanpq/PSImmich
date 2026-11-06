function Export-IMAssetThumbnail
{
    <#
    .SYNOPSIS
        Exports Immich asset thumbnails
    .DESCRIPTION
        Downloads and saves thumbnail images for Immich assets to a local directory. Thumbnails are saved
        as JPEG files with the asset UUID as the filename.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the asset to export the thumbnail for. Accepts pipeline input.
    .PARAMETER Path
        The local directory where the thumbnail file will be saved. The file will be named using the asset UUID with a .jpeg extension.
    .EXAMPLE
        Export-IMAssetThumbnail -Id 'asset-uuid' -Path 'C:\Thumbnails'

        Exports the thumbnail for the specified asset to the C:\Thumbnails directory.
    .EXAMPLE
        Get-IMAsset -Random -Count 10 | Export-IMAssetThumbnail -Path 'C:\RandomThumbnails'

        Exports thumbnails for 10 random assets using pipeline input.
    .EXAMPLE
        Get-IMAsset -TagId 'portrait-tag' | Export-IMAssetThumbnail -Path 'C:\Portraits\Thumbs'

        Exports thumbnails for all assets tagged as portraits.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter()]
        [System.IO.DirectoryInfo]
        $Path
    )

    process
    {
        $Id | ForEach-Object {
            $CurrentID = $PSItem
            $OutputPath = Join-Path -Path $Path -ChildPath "$($CurrentID).jpeg"
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $SavedProgressPreference = $global:ProgressPreference
                $global:ProgressPreference = 'SilentlyContinue'
            }
            InvokeImmichRestMethod -Method Get -RelativePath "/assets/$Id/thumbnail" -ImmichSession:$Session -ContentType 'application/octet-stream' -OutFilePath $OutputPath
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $global:ProgressPreference = $SavedProgressPreference
            }
        }
    }

}
#endregion
