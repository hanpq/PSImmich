function Get-IMMapMarker
{
    <#
    .DESCRIPTION
        Retreives map markers
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
    .PARAMETER WithSharedAlbums
        With shared albums filter
    .EXAMPLE
        Get-IMMapMarker

        Retreives map markers
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
        $WithPartners,

        [Parameter()]
        [boolean]
        $WithSharedAlbums
    )

    BEGIN
    {
        $QueryParameters = @{}
        $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'CreatedAfter', 'CreatedBefore', 'IsArchived', 'IsFavorite', 'WithPartners', 'WithSharedAlbums' -NameMapping @{
                CreatedAfter     = 'fileCreatedAfter'
                CreatedBefore    = 'fileCreatedBefore'
                IsArchived       = 'isArchived'
                IsFavorite       = 'isFavorite'
                WithPartners     = 'withPartners'
                WithSharedAlbums = 'withSharedAlbums'
            })
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/map/markers' -ImmichSession:$Session -QueryParameters $QueryParameters
    }
}
#endregion
