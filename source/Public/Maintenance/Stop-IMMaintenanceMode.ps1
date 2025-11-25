function Stop-IMMaintenanceMode
{
    <#
    .SYNOPSIS
        Stops Immich maintenance mode
    .DESCRIPTION
        Takes Immich out of maintenance mode, restoring normal read-write operations.
        This should be called after completing maintenance tasks to restore full functionality.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .EXAMPLE
        Stop-IMMaintenanceMode

        Takes the current Immich instance out of maintenance mode.
    .EXAMPLE
        Stop-IMMaintenanceMode -Session $MySession

        Takes the specified Immich instance out of maintenance mode.
    .NOTES
        This cmdlet requires administrative privileges and supports ShouldProcess.
        After calling this, users will regain full access to Immich functionality.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    Write-Warning 'This function is disabled because we can only enter maintenance mode but not exit it trough API usage. Until this API feature reaches stable, use immich-admin CLI to start and stop maintenance mode.'
    break

    $ConfirmationMessage = 'Take Immich instance out of maintenance mode (restore full functionality)'
    $WhatIfDescription = 'Would take Immich out of maintenance mode'
    $ConfirmCaption = 'Stop Maintenance Mode'

    if ($PSCmdlet.ShouldProcess($ConfirmationMessage, $WhatIfDescription, $ConfirmCaption))
    {
        $Body = @{
            action = 'end'
        }

        InvokeImmichRestMethod -Method POST -RelativePath '/admin/maintenance' -ImmichSession $Session -Body $Body
    }
}
