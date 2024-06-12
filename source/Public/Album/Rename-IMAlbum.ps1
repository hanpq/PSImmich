function Rename-IMAlbum
{
    <#
    .DESCRIPTION
        Renames an Immich album
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines albums to update
    .PARAMETER NewName
        Defines a new album name
    .EXAMPLE
        Rename-IMAlbum -id <albumid> -NewName 'New York 2024'

        Renames the album
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
        $id,

        [Parameter(Mandatory)]
        [string]
        $NewName
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'NewName' -NameMapping @{
                NewName = 'albumName'
            })
    }

    PROCESS
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Update'))
            {
                InvokeImmichRestMethod -Method PATCH -RelativePath "/albums/$PSItem" -ImmichSession:$Session -Body:$BodyParameters
            }
        }
    }
}
#endregion
