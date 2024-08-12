function Set-IMUserPreference
{
    <#
    .DESCRIPTION
        Set Immich user preference
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the user id to update
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
        [ValidateSet('primary', 'pink', 'red', 'yellow', 'blue', 'green', 'purple', 'orange', 'gray', 'amber')]
        [string]
        $AvatarColor,

        [Parameter()]
        [int]
        $DownloadArchiveSize,

        [Parameter()]
        [boolean]
        $EmailNotificationForAlbumInvite,

        [Parameter()]
        [boolean]
        $EmailNotificationForAlbumUpdate,

        [Parameter()]
        [boolean]
        $EmailNotificationEnabled,

        [Parameter()]
        [boolean]
        $MemoriesEnabled,

        [Parameter()]
        [datetime]
        $HideBuyButtonUntil,

        [Parameter()]
        [boolean]
        $ShowSupportBadge
    )

    BEGIN
    {
        $Body = @{}
        $Body.avatar += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'AvatarColor' -NameMapping @{
                AvatarColor = 'color'
        })
        $Body.download += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'DownloadArchiveSize' -NameMapping @{
                DownloadArchiveSize = 'archiveSize'
        })
        $Body.emailNotifications += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'EmailNotificationForAlbumInvite','EmailNotificationForAlbumUpdate','EmailNotificationEnabled' -NameMapping @{
                EmailNotificationForAlbumInvite = 'albumInvite'
                EmailNotificationForAlbumUpdate = 'albumUpdate'
                EmailNotificationEnabled = 'enabled'
        })
        $Body.memories += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'MemoriesEnabled' -NameMapping @{
                MemoriesEnabled = 'enabled'
        })
        $Body.purchase += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'HideBuyButtonUntil','ShowSupportBadge' -NameMapping @{
                HideBuyButtonUntil = 'hideBuyButtonUntil'
                ShowSupportBadge = 'showSupportBadge'
        })

        # The above body keys are added regardless of if they are actually populated. Therefor remove empty ones.
        $Body.Clone().Keys | foreach-object {if ($Body.$PSItem.Count -eq 0) {$Body.Remove($PSItem)}}
    }

    PROCESS
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem,'Set')) {
                InvokeImmichRestMethod -Method PUT -RelativePath "/admin/users/$PSItem/preferences" -ImmichSession:$Session -Body $Body
            }
        }
    }

}
#endregion
