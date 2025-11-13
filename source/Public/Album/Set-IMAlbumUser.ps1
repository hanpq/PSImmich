function Set-IMAlbumUser
{
    <#
    .SYNOPSIS
        Updates user roles in an Immich album
    .DESCRIPTION
        Changes the role of one or more users in an Immich album. Users can be promoted or demoted between
        editor (full access) and viewer (read-only) roles.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER AlbumId
        The UUID of the album to update user roles in.
    .PARAMETER UserId
        The UUID(s) of the user(s) whose roles should be updated. Accepts pipeline input and multiple values.
    .PARAMETER Role
        The new role to assign to the user(s). Valid values are 'editor' (can modify album) or 'viewer' (read-only access).
    .EXAMPLE
        Set-IMAlbumUser -AlbumId 'album-uuid' -UserId 'user-uuid' -Role 'editor'

        Promotes a user to editor role in the specified album.
    .EXAMPLE
        @('user1-uuid', 'user2-uuid') | Set-IMAlbumUser -AlbumId 'album-uuid' -Role 'viewer'

        Changes multiple users to viewer role via pipeline.
    .EXAMPLE
        Get-IMAlbum -AlbumId 'album-uuid' | Get-IMAlbumUsers | Where-Object {$_.role -eq 'editor'} | Set-IMAlbumUser -AlbumId 'album-uuid' -Role 'viewer'

        Demotes all current editors to viewers in the album.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before changing user roles.
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

        [Parameter(Mandatory)]
        [ValidateSet('editor', 'viewer')]
        [ApiParameter('role')]
        [string]
        $Role
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        $UserId | ForEach-Object {
            InvokeImmichRestMethod -Method PUT -RelativePath "/albums/$AlbumId/user/$PSItem" -ImmichSession:$Session -Body:$BodyParameters
        }
    }
}
#endregion
