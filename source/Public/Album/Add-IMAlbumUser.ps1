﻿function Add-IMAlbumUser
{
    <#
    .DESCRIPTION
        Add user to album
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines albumId to add assets to
    .PARAMETER userId
        Defines the assetIds to add to the album
    .EXAMPLE
        Add-IMAlbumUser

        Add user to album
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [string]
        $albumId,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string[]]
        $userId
    )

    BEGIN
    {
        $BodyParameters = @{
            sharedUserIds = [string[]]@()
        }
    }

    PROCESS
    {
        $userId | ForEach-Object {
            $BodyParameters.sharedUserIds += $PSItem
        }
    }

    END
    {
        InvokeImmichRestMethod -Method PUT -RelativePath "/album/$albumid/users" -ImmichSession:$Session -Body:$BodyParameters
    }
}
#endregion