﻿function Get-IMAssetMapMarker
{
    <#
    .DESCRIPTION
        Retreives asset map markers
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER CreatedAfter
        Created after filter
    .PARAMETER CreatedBefore
        Created before filter
    .PARAMETER IsArchived
        Archived filter
    .PARAMETER IsFavorite
        Favorite filter
    .PARAMETER WithPartners
        With partners filter
    .EXAMPLE
        Get-IMAssetMapMarker

        Retreives asset map markers
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [datetime]
        $CreatedAfter,

        [Parameter()]
        [datetime]
        $CreatedBefore,

        [Parameter()]
        [boolean]
        $IsArchived,

        [Parameter()]
        [boolean]
        $IsFavorite,

        [Parameter()]
        [boolean]
        $WithPartners
    )

    BEGIN
    {
        $QueryParameters = @{}
        $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'CreatedAfter', 'CreatedBefore', 'IsArchived', 'IsFavorite', 'WithPartners' -NameMapping @{
                CreatedAfter  = 'fileCreatedAfter'
                CreatedBefore = 'fileCreatedBefore'
                IsArchived    = 'isArchived'
                IsFavorite    = 'isFavorite'
                WithPartners  = 'withPartners'
            })
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/asset/map-marker' -ImmichSession:$Session -QueryParameters $QueryParameters
    }
}
#endregion
