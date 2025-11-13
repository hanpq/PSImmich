function Remove-IMServerLicense
{
    <#
    .SYNOPSIS
        Removes Immich server license.
    .DESCRIPTION
        Deactivates and removes the current server license.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Remove-IMServerLicense

        Removes current server license.
    .NOTES
        Supports -WhatIf and -Confirm for safety.
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    if ($PSCmdlet.ShouldProcess('Service license', 'remove'))
    {
        InvokeImmichRestMethod -Method Delete -RelativePath '/server/license' -ImmichSession:$Session
    }

}
#endregion
