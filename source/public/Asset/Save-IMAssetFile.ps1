function Save-IMAssetFile
{
    <#
    .SYNOPSIS
        Downloads stored Immich asset files to local storage
    .DESCRIPTION
        Downloads a stored asset file, such as a preview, thumbnail or sidecar, to a local directory.
        The file keeps the name it has in Immich. Use Get-IMAssetFile to find file IDs.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the asset file to download. Accepts pipeline input.
    .PARAMETER Path
        The local directory where the downloaded file will be saved.
    .EXAMPLE
        Save-IMAssetFile -Id '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' -Path 'C:\Downloads'

        Downloads the specified asset file to the C:\Downloads directory.
    .EXAMPLE
        Get-IMAssetFile -AssetId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Type sidecar | Save-IMAssetFile -Path 'C:\Sidecars'

        Downloads all sidecar files of an asset to a local folder.
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

        [Parameter(Mandatory)]
        [System.IO.DirectoryInfo]
        $Path
    )

    process
    {
        $AssetFile = Invoke-ImmichApiGetAssetFile -Id $Id -ImmichSession $Session
        $FileName = Split-Path -Path $AssetFile.path -Leaf
        $OutputPath = Join-Path -Path $Path.FullName -ChildPath $FileName

        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            $SavedProgressPreference = $global:ProgressPreference
            $global:ProgressPreference = 'SilentlyContinue'
        }
        try
        {
            Invoke-ImmichApiDownloadAssetFile -Id $Id -OutFilePath $OutputPath -ImmichSession $Session
        }
        finally
        {
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $global:ProgressPreference = $SavedProgressPreference
            }
        }
    }
}
#endregion
