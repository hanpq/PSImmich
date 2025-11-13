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
        [ApiParameter('fileCreatedAfter')]
        [datetime]
        $CreatedAfter,

        [Parameter()]
        [ApiParameter('fileCreatedBefore')]
        [datetime]
        $CreatedBefore,

        [Parameter()]
        [ApiParameter('isArchived')]
        [boolean]
        $IsArchived,

        [Parameter()]
        [ApiParameter('isFavorite')]
        [boolean]
        $IsFavorite,

        [Parameter()]
        [ApiParameter('withPartners')]
        [boolean]
        $WithPartners,

        [Parameter()]
        [ApiParameter('withSharedAlbums')]
        [boolean]
        $WithSharedAlbums
    )

    begin
    {
        $QueryParameters = @{}
        $QueryParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/map/markers' -ImmichSession:$Session -QueryParameters $QueryParameters
    }
}
#endregion
