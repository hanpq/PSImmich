function Get-IMRandomAsset
{
    <#
    .DESCRIPTION
        Retreives random assets
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Count
        asd
    .EXAMPLE
        Get-IMRandomAsset

        Retreives random assets
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [int]
        $Count
    )

    BEGIN
    {
        $QueryParameters = @{}
        $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'Count' -NameMapping @{
                Count = 'count'
            })
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/asset/random' -ImmichSession:$Session -QueryParameters $QueryParameters
    }
}
#endregion
