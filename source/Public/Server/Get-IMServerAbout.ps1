function Get-IMServerAbout
{
    <#
    .DESCRIPTION
        Retreives Immich server about
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMServerAbout

        Retreives Immich server about
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/server/about' -ImmichSession:$Session

}
#endregion
