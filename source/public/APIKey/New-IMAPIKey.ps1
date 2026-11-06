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
        such as 'asset.read', 'album.create', etc.
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
        [ValidateSet('all', 'activity.create', 'activity.read', 'activity.update', 'activity.delete', 'activity.statistics', 'apiKey.create', 'apiKey.read', 'apiKey.update', 'apiKey.delete', 'asset.read', 'asset.update', 'asset.delete', 'asset.share', 'asset.view', 'asset.download', 'asset.upload', 'album.create', 'album.read', 'album.update', 'album.delete', 'album.statistics', 'album.addAsset', 'album.removeAsset', 'album.share', 'album.download', 'authDevice.delete', 'archive.read', 'face.create', 'face.read', 'face.update', 'face.delete', 'library.create', 'library.read', 'library.update', 'library.delete', 'library.statistics', 'timeline.read', 'timeline.download', 'memory.create', 'memory.read', 'memory.update', 'memory.delete', 'partner.create', 'partner.read', 'partner.update', 'partner.delete', 'person.create', 'person.read', 'person.update', 'person.delete', 'person.statistics', 'person.merge', 'person.reassign', 'session.read', 'session.update', 'session.delete', 'sharedLink.create', 'sharedLink.read', 'sharedLink.update', 'sharedLink.delete', 'stack.create', 'stack.read', 'stack.update', 'stack.delete', 'systemConfig.read', 'systemConfig.update', 'systemMetadata.read', 'systemMetadata.update', 'tag.create', 'tag.read', 'tag.update', 'tag.delete', 'tag.asset', 'admin.user.create', 'admin.user.read', 'admin.user.update', 'admin.user.delete')]
        [ApiParameter('permissions')]
        [string[]]
        $Permission = 'all'
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        InvokeImmichRestMethod -Method POST -RelativePath '/api-keys' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
