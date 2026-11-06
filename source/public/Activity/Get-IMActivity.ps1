function Get-IMActivity
{
    <#
    .SYNOPSIS
        Retrieves activities from an Immich album
    .DESCRIPTION
        Retrieves activities (comments and likes) from an Immich album. Can be filtered by asset, activity type,
        user, or activity level (album vs asset level).
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER AlbumId
        The UUID of the album to retrieve activities from. Accepts pipeline input.
    .PARAMETER AssetId
        The UUID of a specific asset to retrieve activities for. If specified, only activities related to this asset are returned.
    .PARAMETER Level
        The level of activities to retrieve. Valid values are 'album' or 'asset'.
    .PARAMETER Type
        The type of activities to retrieve. Valid values are 'comment' or 'like'.
    .PARAMETER UserId
        The UUID of a specific user to retrieve activities for. If specified, only activities by this user are returned.
    .EXAMPLE
        Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retrieves all activities for the specified album.
    .EXAMPLE
        Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'

        Retrieves all activities for a specific asset within the album.
    .EXAMPLE
        Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Type 'comment'

        Retrieves only comment activities for the album.
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
        $AssetId,

        [Parameter()]
        [ValidateSet('album', 'asset')]
        [ApiParameter('level')]
        [string]
        $Level,

        [Parameter()]
        [ValidateSet('comment', 'like')]
        [ApiParameter('type')]
        [string]
        $Type,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('userId')]
        [string]
        $UserId
    )

    begin
    {
        $QueryParameters = @{}
        $QueryParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/activities' -ImmichSession:$Session -QueryParameters $QueryParameters | AddCustomType IMActivity
    }

}
#endregion
