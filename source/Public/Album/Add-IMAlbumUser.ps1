function Add-IMAlbumUser
{
    <#
    .DESCRIPTION
        Add user to album
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines album to add the user to
    .PARAMETER userId
        Defines the user to add to the album
    .PARAMETER role
        Defines the user role
    .EXAMPLE
        Add-IMAlbumUser -albumid <albumid> -userid <userid> -role editor

        Add user to album
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
