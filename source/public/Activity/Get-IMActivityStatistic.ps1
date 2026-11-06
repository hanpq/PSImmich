function Get-IMActivityStatistic
{
    <#
    .SYNOPSIS
        Retrieves activity statistics for an Immich album
    .DESCRIPTION
        Retrieves statistical information about activities in an Immich album, such as the number of comments
        and likes. Can provide statistics for the entire album or for a specific asset.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER AlbumId
        The UUID of the album to retrieve activity statistics for. Accepts pipeline input.
    .PARAMETER AssetId
        The UUID of a specific asset to retrieve activity statistics for. If specified, returns statistics only for this asset.
    .EXAMPLE
        Get-IMActivityStatistic -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retrieves activity statistics for the entire album.
    .EXAMPLE
        Get-IMActivityStatistic -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'

        Retrieves activity statistics for a specific asset within the album.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('albumId')]
        [string]
        $AlbumId,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('assetId')]
        [string]
        $AssetId
    )

    begin
    {
        $QueryParameters = @{}
        $QueryParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/activities/statistics' -ImmichSession:$Session -QueryParameters $QueryParameters
    }

}
#endregion
