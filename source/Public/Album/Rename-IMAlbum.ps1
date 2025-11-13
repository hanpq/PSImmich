function Rename-IMAlbum
{
    <#
    .SYNOPSIS
        Renames Immich albums
    .DESCRIPTION
        Changes the name of one or more Immich albums. This is a convenient wrapper around Set-IMAlbum
        specifically for renaming operations.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the album(s) to rename. Accepts pipeline input and multiple values.
    .PARAMETER NewName
        The new name for the album(s).
    .EXAMPLE
        Rename-IMAlbum -Id 'album-uuid' -NewName 'Family Vacation 2024'

        Renames the specified album.
    .EXAMPLE
        Get-IMAlbum -SearchString 'temp*' | Rename-IMAlbum -NewName 'Archived Photos'

        Renames all albums with names starting with 'temp' to 'Archived Photos'.
    .EXAMPLE
        Rename-IMAlbum -Id 'album-uuid' -NewName 'Wedding Photos' -Confirm:$false

        Renames the album without confirmation prompt.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before renaming albums.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('ids', 'albumId')]
        [string[]]
        $Id,

        [Parameter(Mandatory)]
        [ApiParameter('albumName')]
        [string]
        $NewName
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        $Id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Update'))
            {
                InvokeImmichRestMethod -Method PATCH -RelativePath "/albums/$PSItem" -ImmichSession:$Session -Body:$BodyParameters
            }
        }
    }
}
#endregion
