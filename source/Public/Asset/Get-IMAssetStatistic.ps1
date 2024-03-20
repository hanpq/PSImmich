function Get-IMAssetStatistic
{
    <#
    .DESCRIPTION
        Retreives asset statistic
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER isArchived
        Archived filter
    .PARAMETER isFavorite
        Favorite filter
    .PARAMETER isTrashed
        Trashed filter
    .EXAMPLE
        Get-IMAssetStatistic

        Retreives asset statistic
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [boolean]
        $isArchived,

        [Parameter()]
        [boolean]
        $isFavorite,

        [Parameter()]
        [boolean]
        $isTrashed
    )

    BEGIN
    {
        $QueryParameters = @{}
        $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'isArchived', 'isFavorite', 'isTrashed')
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/asset/statistics' -ImmichSession:$Session -QueryParameters $QueryParameters
    }
}
#endregion
