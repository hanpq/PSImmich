function Get-IMTheme
{
    <#
    .DESCRIPTION
        Retreives Immich theme CSS
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMTheme

        Retreives Immich theme CSS
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/server/theme' -ImmichSession:$Session

}
#endregion
