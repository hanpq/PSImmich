function Get-IMTimeBucket
{
    <#
    .SYNOPSIS
        Retrieves timeline time buckets.
    .DESCRIPTION
        Gets time-based groupings of assets for timeline display and navigation.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER AlbumId
        Filter by album ID.
    .PARAMETER Bbox
        Bounding box filter (west,south,east,north) for asset coordinates.
    .PARAMETER IsFavorite
        Filter by favorite status.
    .PARAMETER IsTrashed
        Filter by trash status.
    .PARAMETER Key
        Shared link key for access.
    .PARAMETER Order
        Sort order for results.
    .PARAMETER OrderBy
        Field used to order assets: takenAt or createdAt.
    .PARAMETER PersonId
        Filter by person ID.
    .PARAMETER Slug
        Shared link slug for access.
    .PARAMETER TagId
        Filter by tag ID.
    .PARAMETER TimeBucket
        Time bucket to retrieve assets for (uses the single-bucket endpoint).
    .PARAMETER UserId
        Filter by user ID.
    .PARAMETER Visibility
        Filter by visibility: archive, timeline, hidden, or locked.
    .PARAMETER WithCoordinates
        Only include assets with coordinates.
    .PARAMETER WithPartners
        Include assets from partners.
    .PARAMETER WithStacked
        Include stacked assets.
    .EXAMPLE
        Get-IMTimeBucket

        Retreives timebucket
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $AlbumId,

        [Parameter()]
        [string]
        $Bbox,

        [Parameter()]
        [bool]
        $IsFavorite,

        [Parameter()]
        [bool]
        $IsTrashed,

        [Parameter()]
        [string]
        $Key,

        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [string]
        $Order,

        [Parameter()]
        [ValidateSet('takenAt', 'createdAt')]
        [string]
        $OrderBy,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $PersonId,

        [Parameter()]
        [string]
        $Slug,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $TagId,

        [Parameter(Mandatory, ParameterSetName = 'timebucket')]
        [string]
        $TimeBucket,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $UserId,

        [Parameter()]
        [ValidateSet('archive', 'timeline', 'hidden', 'locked')]
        [string]
        $Visibility,

        [Parameter()]
        [bool]
        $WithCoordinates,

        [Parameter()]
        [bool]
        $WithPartners,

        [Parameter()]
        [bool]
        $WithStacked
    )

    $ApiParams = @{ ImmichSession = $Session }
    foreach ($Name in 'AlbumId', 'Bbox', 'IsFavorite', 'IsTrashed', 'Key', 'Order', 'OrderBy', 'PersonId', 'Slug', 'TagId', 'UserId', 'Visibility', 'WithCoordinates', 'WithPartners', 'WithStacked')
    {
        if ($PSBoundParameters.ContainsKey($Name))
        {
            $ApiParams[$Name] = $PSBoundParameters[$Name]
        }
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'list'
        {
            Invoke-ImmichApiGetTimeBuckets @ApiParams
        }
        'timebucket'
        {
            $ApiParams['TimeBucket'] = $TimeBucket
            Invoke-ImmichApiGetTimeBucket @ApiParams
        }
    }
}
#endregion
