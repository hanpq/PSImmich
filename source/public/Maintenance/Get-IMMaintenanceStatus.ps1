function Get-IMMaintenanceStatus
{
    <#
    .SYNOPSIS
        Retrieves the Immich maintenance mode status
    .DESCRIPTION
        Shows whether the Immich server is in maintenance mode, the current maintenance action, its progress and any error that occurred.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .EXAMPLE
        Get-IMMaintenanceStatus

        Retrieves the current maintenance mode status of the Immich server.
    .EXAMPLE
        Get-IMMaintenanceStatus | Select-Object -ExpandProperty active

        Returns $true when the server is in maintenance mode.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    process
    {
        [MaintenanceStatusResponseDto]::new((Invoke-ImmichApiGetMaintenanceStatus -ImmichSession $Session))
    }
}
