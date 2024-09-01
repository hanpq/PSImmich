function Get-IMServerFeature
{
    <#
    .DESCRIPTION
        Retreives Immich server feature
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMServerFeature

        Retreives Immich server feature
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/features' -ImmichSession:$Session

}
#endregion
