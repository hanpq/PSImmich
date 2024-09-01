function New-IMAPIKey
{
    <#
    .DESCRIPTION
        Adds a new an api key
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER name
        Defines the name of the new api key
    .PARAMETER permission
        Defines the permissions for the API-key
    .EXAMPLE
        New-IMAPIKey -name 'Automation'

        Adds a new an api key
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [string]
        $name,

        [Parameter()]
        [ValidateSet("all", "activity.create", "activity.read", "activity.update", "activity.delete", "activity.statistics", "apiKey.create", "apiKey.read", "apiKey.update", "apiKey.delete", "asset.read", "asset.update", "asset.delete", "asset.share", "asset.view", "asset.download", "asset.upload", "album.create", "album.read", "album.update", "album.delete", "album.statistics", "album.addAsset", "album.removeAsset", "album.share", "album.download", "authDevice.delete", "archive.read", "face.create", "face.read", "face.update", "face.delete", "library.create", "library.read", "library.update", "library.delete", "library.statistics", "timeline.read", "timeline.download", "memory.create", "memory.read", "memory.update", "memory.delete", "partner.create", "partner.read", "partner.update", "partner.delete", "person.create", "person.read", "person.update", "person.delete", "person.statistics", "person.merge", "person.reassign", "session.read", "session.update", "session.delete", "sharedLink.create", "sharedLink.read", "sharedLink.update", "sharedLink.delete", "stack.create", "stack.read", "stack.update", "stack.delete", "systemConfig.read", "systemConfig.update", "systemMetadata.read", "systemMetadata.update", "tag.create", "tag.read", "tag.update", "tag.delete", "tag.asset", "admin.user.create", "admin.user.read", "admin.user.update", "admin.user.delete")]
        [string[]]
        $Permission = 'all'
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'name','permission' -NameMapping @{name = 'name'; Permission = 'permissions'})
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method POST -RelativePath '/api-keys' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
