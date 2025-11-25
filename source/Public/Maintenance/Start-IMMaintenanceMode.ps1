function Start-IMMaintenanceMode
{
    <#
    .SYNOPSIS
        Starts Immich maintenance mode
    .DESCRIPTION
        Puts Immich into maintenance mode, making it read-only for administrative operations.
        This is typically used before performing maintenance tasks like backups or updates.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .EXAMPLE
        Start-IMMaintenanceMode

        Puts the current Immich instance into maintenance mode.
    .EXAMPLE
        Start-IMMaintenanceMode -Session $MySession

        Puts the specified Immich instance into maintenance mode.
    .NOTES
        This cmdlet requires administrative privileges and supports ShouldProcess.
        Users will see a maintenance message when trying to access Immich while in maintenance mode.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    Write-Warning 'This function is disabled because we can only enter maintenance mode but not exit it trough API usage. Until this API feature reaches stable, use immich-admin CLI to start and stop maintenance mode.'
    break

    $ConfirmationMessage = 'Put Immich instance into maintenance mode (read-only state)'
    $WhatIfDescription = 'Would put Immich into maintenance mode'
    $ConfirmCaption = 'Start Maintenance Mode'

    if ($PSCmdlet.ShouldProcess($ConfirmationMessage, $WhatIfDescription, $ConfirmCaption))
    {
        $Body = @{
            action = 'start'
        }

        InvokeImmichRestMethod -Method POST -RelativePath '/admin/maintenance' -ImmichSession:$Session -Body $Body
    }
}
