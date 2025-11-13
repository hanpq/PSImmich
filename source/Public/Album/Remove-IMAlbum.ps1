function Remove-IMAlbum
{
    <#
    .SYNOPSIS
        Removes Immich albums
    .DESCRIPTION
        Removes one or more albums from the Immich server. This action is permanent and cannot be undone.
        All assets in the album will remain in the library but will no longer be organized in the deleted album.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER AlbumId
        The UUID(s) of the album(s) to remove. Accepts pipeline input and multiple values.
    .EXAMPLE
        Remove-IMAlbum -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Removes the specified album with confirmation prompt.
    .EXAMPLE
        Get-IMAlbum -SearchString 'temp*' | Remove-IMAlbum

        Removes all albums with names starting with 'temp'.
    .EXAMPLE
        Remove-IMAlbum -AlbumId 'album-uuid' -Confirm:$false

        Removes the album without confirmation prompt.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing albums.
        Assets within the album are not deleted, only the album container is removed.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('id')]
        [string[]]
        $AlbumId
    )

    process
    {
        # We loop through IDs because ids can be provided as an array to the parameter in which case the process block only gets called once.
        $AlbumId | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'DELETE'))
            {
                InvokeImmichRestMethod -Method Delete -RelativePath "/albums/$CurrentID" -ImmichSession:$Session
            }
        }
    }
}
#endregion
