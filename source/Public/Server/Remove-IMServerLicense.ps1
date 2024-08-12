function Remove-IMServerLicense
{
    <#
    .DESCRIPTION
        Removes Immich server license
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Remove-IMServerLicense

        Removes Immich server license
    #>

    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    if ($PSCmdlet.ShouldProcess('Service license', 'remove')) {
        InvokeImmichRestMethod -Method Delete -RelativePath "/server/license" -ImmichSession:$Session
    }

}
#endregion
