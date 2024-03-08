function Get-IMServerConfig
{
    <#
    .DESCRIPTION
        Retreives Immich server config
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMServerConfig

        Retreives Immich server config
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server-info/config' -ImmichSession:$Session

}
#endregion
