function New-IMNotification
{
    <#
    .SYNOPSIS
        Sends a notification to a specific Immich user
    .DESCRIPTION
        Creates a notification in the notification inbox of a user on the Immich server. This is an administrator
        operation. Only the parameters you specify are sent, so Immich applies its own defaults for the rest.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER UserId
        The UUID of the user to send the notification to.
    .PARAMETER Title
        The title of the notification.
    .PARAMETER Description
        Optional description text shown with the notification.
    .PARAMETER Level
        The severity of the notification: success, error, warning or info.
    .PARAMETER Type
        The notification type. Use Custom for messages created by an administrator.
    .PARAMETER Data
        Optional additional data attached to the notification as a hashtable.
    .EXAMPLE
        New-IMNotification -UserId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Title 'Maintenance tonight'

        Sends a notification with the specified title to the user.
    .EXAMPLE
        New-IMNotification -UserId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Title 'Backup failed' -Level error -Type BackupFailed -Description 'Check the server log.'

        Sends an error notification describing a failed backup.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('userId')]
        [string]
        $UserId,

        [Parameter(Mandatory)]
        [ApiParameter('title')]
        [string]
        $Title,

        [Parameter()]
        [ApiParameter('description')]
        [string]
        $Description,

        [Parameter()]
        [ValidateSet('success', 'error', 'warning', 'info')]
        [ApiParameter('level')]
        [string]
        $Level,

        [Parameter()]
        [ValidateSet('JobFailed', 'BackupFailed', 'SystemMessage', 'AlbumInvite', 'AlbumUpdate', 'ClusterGroupRequest', 'Custom')]
        [ApiParameter('type')]
        [string]
        $Type,

        [Parameter()]
        [ApiParameter('data')]
        [hashtable]
        $Data
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        Invoke-ImmichApiCreateNotification -Body $BodyParameters -ImmichSession $Session | ForEach-Object { [NotificationDto]::new($PSItem) }
    }
}
#endregion
