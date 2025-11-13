function Add-IMActivity
{
    <#
    .SYNOPSIS
        Adds a new activity to an Immich album
    .DESCRIPTION
        Adds a new activity (comment or like) to an Immich album or specific asset within an album.
        Activities provide a way to interact with and comment on media in shared albums.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER AlbumId
        The UUID of the album to add the activity to. Accepts pipeline input.
    .PARAMETER AssetId
        The UUID of a specific asset to add the activity to. If not specified, the activity applies to the album level.
    .PARAMETER Comment
        The comment text to add. Required when Type is 'comment'.
    .PARAMETER Type
        The type of activity to add. Valid values are 'comment' or 'like'.
    .EXAMPLE
        Add-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Comment 'Amazing sunset!' -Type 'comment'

        Adds a comment to the specified album.
    .EXAMPLE
        Add-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' -Type 'like'

        Adds a like to a specific asset within the album.
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
        [ApiParameter('comment')]
        [string]
        $Comment,

        [Parameter()]
        [ValidateSet('comment', 'like')]
        [ApiParameter('type')]
        [string]
        $Type
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/activities' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
