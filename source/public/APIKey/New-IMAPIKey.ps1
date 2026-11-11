function New-IMAPIKey
{
    <#
    .SYNOPSIS
        Creates a new Immich API key
    .DESCRIPTION
        Creates a new API key for programmatic access to the Immich server. API keys can be assigned specific
        permissions to control access to different parts of the API.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Name
        The name for the new API key. This should be descriptive to help identify the key's purpose.
    .PARAMETER Permission
        The permissions to assign to the API key. Defaults to 'all' for full access. Can specify multiple granular permissions
        such as 'asset.read', 'album.create', etc. Values match the Immich 3.4 permission enum; older permission names
        that are absent from that enum are not accepted.
    .EXAMPLE
        New-IMAPIKey -Name 'Automation Script'

        Creates a new API key with full permissions named 'Automation Script'.
    .EXAMPLE
        New-IMAPIKey -Name 'Read Only Access' -Permission 'asset.read','album.read','library.read'

        Creates a new API key with limited read-only permissions.
    .NOTES
        The API key secret is only displayed once upon creation. Store it securely as it cannot be retrieved later.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ApiParameter('name')]
        [string]
        $Name,

        [Parameter()]
        [ValidateSet(
            'all', 'activity.create', 'activity.read', 'activity.update', 'activity.delete',
            'activity.statistics', 'apiKey.create', 'apiKey.read', 'apiKey.update', 'apiKey.delete',
            'apiKey.rotate', 'asset.read', 'asset.update', 'asset.delete', 'asset.statistics',
            'asset.share', 'asset.view', 'asset.download', 'asset.upload', 'asset.copy',
            'asset.derive', 'assetFile.read', 'assetFile.delete', 'assetFile.download', 'asset.edit.get',
            'asset.edit.create', 'asset.edit.delete', 'album.create', 'album.read', 'album.update',
            'album.delete', 'album.statistics', 'album.share', 'album.download', 'albumAsset.create',
            'albumAsset.delete', 'albumUser.create', 'albumUser.update', 'albumUser.delete', 'auth.changePassword',
            'authDevice.delete', 'archive.read', 'backup.list', 'backup.download', 'backup.upload',
            'backup.delete', 'clusterGroup.read', 'clusterGroup.leave', 'clusterGroup.admin', 'clusterGroupRequest.create',
            'clusterGroupRequest.read', 'clusterGroupRequest.delete', 'adminConfig.read', 'adminConfig.update', 'userConfig.read',
            'duplicate.read', 'duplicate.delete', 'face.create', 'face.read', 'face.update',
            'face.delete', 'folder.read', 'job.create', 'job.read', 'library.create',
            'library.read', 'library.update', 'library.delete', 'library.statistics', 'timeline.read',
            'timeline.download', 'maintenance', 'map.read', 'map.search', 'memory.create',
            'memory.read', 'memory.update', 'memory.delete', 'memory.statistics', 'memoryAsset.create',
            'memoryAsset.delete', 'notification.create', 'notification.read', 'notification.update', 'notification.delete',
            'partner.create', 'partner.read', 'partner.update', 'partner.delete', 'passkey.read',
            'passkey.update', 'passkey.delete', 'person.create', 'person.read', 'person.update',
            'person.delete', 'person.statistics', 'person.merge', 'person.reassign', 'pinCode.create',
            'pinCode.update', 'pinCode.delete', 'plugin.create', 'plugin.read', 'plugin.update',
            'plugin.delete', 'server.about', 'server.apkLinks', 'server.storage', 'server.statistics',
            'server.versionCheck', 'serverLicense.read', 'serverLicense.update', 'serverLicense.delete', 'session.create',
            'session.read', 'session.update', 'session.delete', 'session.lock', 'sharedLink.create',
            'sharedLink.read', 'sharedLink.update', 'sharedLink.delete', 'stack.create', 'stack.read',
            'stack.update', 'stack.delete', 'sync.stream', 'syncCheckpoint.read', 'syncCheckpoint.update',
            'syncCheckpoint.delete', 'systemConfig.read', 'systemConfig.update', 'systemMetadata.read', 'systemMetadata.update',
            'tag.create', 'tag.read', 'tag.update', 'tag.delete', 'tag.asset',
            'user.read', 'user.update', 'userLicense.create', 'userLicense.read', 'userLicense.update',
            'userLicense.delete', 'userOnboarding.read', 'userOnboarding.update', 'userOnboarding.delete', 'userPreference.read',
            'userPreference.update', 'userProfileImage.create', 'userProfileImage.read', 'userProfileImage.update', 'userProfileImage.delete',
            'queue.read', 'queue.update', 'queueJob.create', 'queueJob.read', 'queueJob.update',
            'queueJob.delete', 'workflow.create', 'workflow.read', 'workflow.update', 'workflow.delete',
            'workflow.logs', 'adminUser.create', 'adminUser.read', 'adminUser.update', 'adminUser.delete',
            'adminSession.read', 'adminAuth.unlinkAll'
        )]
        [ApiParameter('permissions')]
        [string[]]
        $Permission = 'all'
    )

    begin
    {
        # The API requires permissions, so send the default even when it is not bound.
        $PSBoundParameters['Permission'] = $Permission
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        Invoke-ImmichApiCreateApiKey -Body $BodyParameters -ImmichSession $Session | ForEach-Object { [ApiKeyCreateResponseDto]::new($PSItem) }
    }

}
#endregion
