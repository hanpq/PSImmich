function Add-IMAlbumUser
{
    <#
    .SYNOPSIS
        Adds users to an Immich album
    .DESCRIPTION
        Adds one or more users to an Immich album with specified roles. This enables album sharing and collaboration.
        Users can be assigned as either editors (can modify) or viewers (read-only access).
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER AlbumId
        The UUID of the album to add users to.
    .PARAMETER UserId
        The UUID(s) of the user(s) to add to the album. Accepts pipeline input and multiple values.
    .PARAMETER Role
        The role to assign to the user(s). Valid values are 'editor' (can modify album) or 'viewer' (read-only access).
    .EXAMPLE
        Add-IMAlbumUser -AlbumId 'album-uuid' -UserId 'user-uuid' -Role 'editor'

        Adds a user to the album with editor permissions.
    .EXAMPLE
        @('user1-uuid', 'user2-uuid') | Add-IMAlbumUser -AlbumId 'album-uuid' -Role 'viewer'

        Adds multiple users to the album with viewer permissions via pipeline.
    .EXAMPLE
        Get-IMUser | Where-Object {$_.name -like 'family*'} | Add-IMAlbumUser -AlbumId 'album-uuid' -Role 'viewer'

        Adds all users with names starting with 'family' to the album as viewers.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before adding users to albums.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $AlbumId,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('id')]
        [string[]]
        $UserId,

        [Parameter()]
        [ValidateSet('editor', 'viewer')]
        [string]
        $Role = 'viewer'
    )

    begin
    {
        $BodyParameters = @{
            albumUsers = [object[]]@()
        }
    }

    process
    {
        $UserId | ForEach-Object {
            $UserObject = [pscustomobject]@{
                userId = $PSItem
                role   = $Role
            }
            $BodyParameters.albumUsers += $UserObject
        }
    }

    end
    {
        InvokeImmichRestMethod -Method PUT -RelativePath "/albums/$AlbumId/users" -ImmichSession:$Session -Body:$BodyParameters
    }
}
#endregion
