function Save-IMAsset
{
    <#
    .SYNOPSIS
        Downloads Immich assets to local storage
    .DESCRIPTION
        Downloads one or more assets from Immich to a local directory, preserving their original filenames.
        Supports downloading original files, thumbnails, or web-optimized versions.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the asset to download. Accepts pipeline input.
    .PARAMETER Key
        An optional API key for shared link access when downloading assets.
    .PARAMETER Path
        The local directory where the downloaded file will be saved. The file will retain its original filename from Immich.
    .EXAMPLE
        Save-IMAsset -Id '550e8400-e29b-41d4-a716-446655440000' -Path 'C:\Downloads'

        Downloads the specified asset to the C:\Downloads directory.
    .EXAMPLE
        Get-IMAsset -Random -Count 5 | Save-IMAsset -Path 'C:\RandomAssets'

        Downloads 5 random assets to the specified directory using pipeline input.
    .EXAMPLE
        Get-IMAsset -TagId 'vacation-tag' | Save-IMAsset -Path 'C:\VacationPhotos'

        Downloads all assets tagged with 'vacation-tag' to a local folder.
    .EXAMPLE
        Save-IMAsset -Id 'asset-uuid' -Path 'C:\Backup' -Key 'shared-key'

        Downloads an asset using a shared link key.
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
        [ApiParameter('key')]
        [string]
        $Key,

        [Parameter()]
        [System.IO.DirectoryInfo]
        $Path
    )

    begin
    {
        $QueryParameters = @{}
        $QueryParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        $Id | ForEach-Object {
            $CurrentID = $PSItem
            $AssetObject = Get-IMAsset -id $CurrentID
            $OutputPath = Join-Path -Path $Path -ChildPath $AssetObject.originalFileName
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $SavedProgressPreference = $global:ProgressPreference
                $global:ProgressPreference = 'SilentlyContinue'
            }
            InvokeImmichRestMethod -Method Get -RelativePath "/assets/$CurrentID/original" -ImmichSession:$Session -QueryParameters $QueryParameters -ContentType 'application/octet-stream' -OutFilePath $OutputPath
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $global:ProgressPreference = $SavedProgressPreference
            }
        }
    }

}
#endregion
