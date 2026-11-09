function Get-IMAssetFile
{
    <#
    .SYNOPSIS
        Retrieves the files stored for Immich assets
    .DESCRIPTION
        Retrieves the stored files of an asset, such as the original, preview, thumbnail, sidecar or encoded video files.
        Use -AssetId to list all files of an asset, optionally filtered by type or edit state, or -Id to retrieve a single file.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER AssetId
        The UUID of the asset whose files to list.
    .PARAMETER IsEdited
        Only return files that belong to an edited version of the asset.
    .PARAMETER IsProgressive
        Only return progressive files.
    .PARAMETER IsTransparent
        Only return files with transparency.
    .PARAMETER Type
        Only return files of the specified type.
    .PARAMETER Id
        The UUID of the asset file to retrieve. Accepts pipeline input.
    .EXAMPLE
        Get-IMAssetFile -AssetId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Lists all stored files of the specified asset.
    .EXAMPLE
        Get-IMAssetFile -AssetId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Type preview

        Lists only the preview files of the specified asset.
    .EXAMPLE
        Get-IMAssetFile -Id '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'

        Retrieves a single asset file by its ID.
    #>
    [CmdletBinding(DefaultParameterSetName = 'asset')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'asset')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $AssetId,

        [Parameter(ParameterSetName = 'asset')]
        [bool]
        $IsEdited,

        [Parameter(ParameterSetName = 'asset')]
        [bool]
        $IsProgressive,

        [Parameter(ParameterSetName = 'asset')]
        [bool]
        $IsTransparent,

        [Parameter(ParameterSetName = 'asset')]
        [ValidateSet('fullsize', 'preview', 'thumbnail', 'sidecar', 'encoded_video')]
        [string]
        $Type,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'id')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id
    )

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'id')
        {
            Invoke-ImmichApiGetAssetFile -Id $Id -ImmichSession $Session | ForEach-Object { [AssetFileResponseDto]::new($PSItem) }
        }
        else
        {
            $ApiArguments = @{ AssetId = $AssetId; ImmichSession = $Session }
            if ($PSBoundParameters.ContainsKey('IsEdited')) { $ApiArguments.IsEdited = $IsEdited }
            if ($PSBoundParameters.ContainsKey('IsProgressive')) { $ApiArguments.IsProgressive = $IsProgressive }
            if ($PSBoundParameters.ContainsKey('IsTransparent')) { $ApiArguments.IsTransparent = $IsTransparent }
            if ($PSBoundParameters.ContainsKey('Type')) { $ApiArguments.Type = $Type }
            Invoke-ImmichApiSearchAssetFiles @ApiArguments | ForEach-Object { [AssetFileResponseDto]::new($PSItem) }
        }
    }
}
#endregion
