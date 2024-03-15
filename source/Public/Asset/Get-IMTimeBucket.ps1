function Get-IMTimeBucket
{
    <#
    .DESCRIPTION
        Retreives timebucket objects
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        asd
    .PARAMETER isArchived
        asd
    .PARAMETER isFavorite
        asd
    .PARAMETER isTrashed
        asd
    .PARAMETER order
        asd
    .PARAMETER personId
        asd
    .PARAMETER size
        asd
    .PARAMETER timeBucket
        asd
    .PARAMETER userId
        asd
    .PARAMETER withPartners
        asd
    .PARAMETER withStacked
        asd
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
        $albumId,

        [Parameter()]
        [boolean]
        $isArchived,

        [Parameter()]
        [boolean]
        $isFavorite,

        [Parameter()]
        [boolean]
        $isTrashed,

        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [string]
        $order = 'asc',

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $personId,

        [Parameter(Mandatory)]
        [ValidateSet('DAY', 'MONTH')]
        [string]
        $size,

        [Parameter(ParameterSetName = 'timebucket')]
        [string]
        $timeBucket,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $userId,

        [Parameter()]
        [boolean]
        $withPartners,

        [Parameter()]
        [boolean]
        $withStacked
    )

    BEGIN
    {
        $QueryParameters = @{}
        $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'albumId', 'isArchived', 'isFavorite', 'isTrashed', 'order', 'personId', 'size', 'timeBucket', 'userId', 'withPartners', 'withStacked')
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/asset/time-buckets' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'timebucket'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/asset/time-bucket' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
        }
    }
}
#endregion
