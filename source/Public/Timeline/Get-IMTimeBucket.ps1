function Get-IMTimeBucket
{
    <#
    .DESCRIPTION
        Retreives timebucket objects
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Albumid filter
    .PARAMETER isFavorite
        Favorite filter
    .PARAMETER isTrashed
        Trashed filter
    .PARAMETER order
        Defines sort order
    .PARAMETER personId
        PersonId filter
    .PARAMETER timeBucket
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
