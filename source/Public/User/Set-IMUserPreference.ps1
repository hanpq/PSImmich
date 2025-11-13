function Set-IMUserPreference
{
    <#
    .SYNOPSIS
        Updates user interface preferences.
    .DESCRIPTION
        Modifies user preferences for interface behavior and appearance.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        User ID to update preferences for.
    .PARAMETER AvatarColor
        Select the avatar color to use. Valid values are primary, pink, red, yellow, blue, green, purple, orange, gray, amber.
    .PARAMETER DownloadArchiveSize
        Not defines
    .PARAMETER EmailNotificationForAlbumInvite
        Select if an email notification should be sent to the user if an album is shared to the user.
    .PARAMETER EmailNotificationForAlbumUpdate
        Select if an email notification should be sent to the user if an album that is shared to the user is updated.
    .PARAMETER EmailNotificationEnabled
        Select if email notifications are enabled.
    .PARAMETER MemoriesEnabled
        Select if memories should be shown to the user
    .PARAMETER HideBuyButtonUntil
        Select if the Buy Immich button should be hidden for, accepts a datetime value.
    .PARAMETER ShowSupportBadge
        Select if the Support Immich badge should be shown.
    .EXAMPLE
        Set-IMUserPreference -id <userid> -AvatarColor green

        Set Immich user preferences
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id,

        [Parameter()]
        [ApiParameter('avatar.color')]
        [ValidateSet('primary', 'pink', 'red', 'yellow', 'blue', 'green', 'purple', 'orange', 'gray', 'amber')]
        [string]
        $AvatarColor,

        [Parameter()]
        [ApiParameter('download.archiveSize')]
        [int]
        $DownloadArchiveSize,

        [Parameter()]
        [ApiParameter('emailNotifications.albumInvite')]
        [boolean]
        $EmailNotificationForAlbumInvite,

        [Parameter()]
        [ApiParameter('emailNotifications.albumUpdate')]
        [boolean]
        $EmailNotificationForAlbumUpdate,

        [Parameter()]
        [ApiParameter('emailNotifications.enabled')]
        [boolean]
        $EmailNotificationEnabled,

        [Parameter()]
        [ApiParameter('memories.enabled')]
        [boolean]
        $MemoriesEnabled,

        [Parameter()]
        [ApiParameter('purchase.hideBuyButtonUntil')]
        [datetime]
        $HideBuyButtonUntil,

        [Parameter()]
        [ApiParameter('purchase.showSupportBadge')]
        [boolean]
        $ShowSupportBadge
    )

    begin
    {
        # Use enhanced ConvertTo-ApiParameters with dot-notation support for nested objects
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)

        # Handle special datetime formatting for purchase.hideBuyButtonUntil
        if ($PSBoundParameters.ContainsKey('HideBuyButtonUntil') -and $BodyParameters.ContainsKey('purchase'))
        {
            $BodyParameters.purchase.hideBuyButtonUntil = $HideBuyButtonUntil.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        }
    }

    process
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Set'))
            {
                InvokeImmichRestMethod -Method PUT -RelativePath "/admin/users/$PSItem/preferences" -ImmichSession:$Session -Body $BodyParameters
            }
        }
    }

}
#endregion
