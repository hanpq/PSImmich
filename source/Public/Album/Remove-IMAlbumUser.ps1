function Remove-IMAlbumUser
{
    <#
    .SYNOPSIS
        Removes users from an Immich album
    .DESCRIPTION
        Removes one or more users from an Immich album, revoking their access to the shared album.
        This action cannot be undone and the users will lose access immediately.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER AlbumId
        The UUID of the album to remove users from.
    .PARAMETER UserId
        The UUID(s) of the user(s) to remove from the album. Accepts pipeline input and multiple values.
    .EXAMPLE
        Remove-IMAlbumUser -AlbumId 'album-uuid' -UserId 'user-uuid'

        Removes a specific user from the album with confirmation prompt.
    .EXAMPLE
        @('user1-uuid', 'user2-uuid') | Remove-IMAlbumUser -AlbumId 'album-uuid'

        Removes multiple users from the album via pipeline.
    .EXAMPLE
        Remove-IMAlbumUser -AlbumId 'album-uuid' -UserId 'user-uuid' -Confirm:$false

        Removes the user without confirmation prompt.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing users from albums.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'albumId', Justification = 'FP')]
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
        $UserId
    )

    process
    {
        $UserId | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'DELETE'))
            {
                InvokeImmichRestMethod -Method DELETE -RelativePath "/albums/$AlbumId/user/$psitem" -ImmichSession:$Session
            }
        }
    }

}
#endregion
