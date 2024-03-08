function Get-IMServerInfo
{
    <#
    .DESCRIPTION
        Retreives Immich server info
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMServerInfo

        Retreives Immich server info
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/server-info' -ImmichSession:$Session

}
#endregion
