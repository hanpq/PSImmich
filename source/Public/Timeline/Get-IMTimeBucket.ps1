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
    .PARAMETER IsFavorite
        Filter by favorite status.
    .PARAMETER IsTrashed
        Filter by trash status.
    .PARAMETER Order
        Sort order for results.
    .PARAMETER PersonId
        Filter by person ID.
    .PARAMETER TimeBucket
        Timebucket
    .PARAMETER userId
        UserId filter
    .PARAMETER withPartners
        With partners filter
    .PARAMETER withStacked
        With stacked filter
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
        [ApiParameter('albumId')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $albumId,

        [Parameter()]
        [ApiParameter('isFavorite')]
        [boolean]
        $isFavorite,

        [Parameter()]
        [ApiParameter('isTrashed')]
        [boolean]
        $isTrashed,

        [Parameter()]
        [ApiParameter('order')]
        [ValidateSet('asc', 'desc')]
        [string]
        $order = 'asc',

        [Parameter()]
        [ApiParameter('personId')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $personId,

        [Parameter(Mandatory, ParameterSetName = 'timebucket')]
        [ApiParameter('timeBucket')]
        [string]
        $timeBucket,

        [Parameter()]
        [ApiParameter('userId')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $userId,

        [Parameter()]
        [ApiParameter('withPartners')]
        [boolean]
        $withPartners,

        [Parameter()]
        [ApiParameter('withStacked')]
        [boolean]
        $withStacked
    )

    begin
    {
        $QueryParameters = @{}
        $QueryParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/timeline/buckets' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'timebucket'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/timeline/bucket' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
        }
    }
}
#endregion
