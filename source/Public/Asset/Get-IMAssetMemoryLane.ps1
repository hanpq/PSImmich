function Get-IMAssetMemoryLane
{
    <#
    .DESCRIPTION
        Retreives asset memory lane
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER DayOfMonth
        asd
    .PARAMETER Month
        asd
    .EXAMPLE
        Get-IMAssetMemoryLane

        Retreives asset map markers
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidateRange(1, 31)]
        [int]
        $DayOfMonth,

        [Parameter(Mandatory)]
        [ValidateRange(1, 12)]
        [int]
        $Month
    )

    BEGIN
    {
        $QueryParameters = @{}
        $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'DayOfMonth', 'Month' -NameMapping @{
                DayOfMonth = 'day'
                Month      = 'month'
            })
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/asset/memory-lane' -ImmichSession:$Session -QueryParameters $QueryParameters
    }
}
#endregion
