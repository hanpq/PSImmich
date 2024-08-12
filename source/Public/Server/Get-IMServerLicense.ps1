function Get-IMServerLicense
{
    <#
    .DESCRIPTION
        Retreives Immich server license
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMServerLicense

        Retreives Immich server license
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath "/server/license" -ImmichSession:$Session

}
#endregion
