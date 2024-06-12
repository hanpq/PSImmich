﻿function Set-IMAlbumUser
{
    <#
    .DESCRIPTION
        Set user role
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
        Set-IMAlbumUser -albumid <albumid> -userid <userid> -role editor

        Changes the role of the user in the specified album
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $albumId,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('id')]
        [string[]]
        $userId,

        [Parameter(Mandatory)]
        [ValidateSet('editor','viewer')]
        [string]
        $Role
    )

    BEGIN
    {
        $BodyParameters = @{
            role = $Role
        }
    }

    PROCESS
    {
        $userId | ForEach-Object {
            InvokeImmichRestMethod -Method PUT -RelativePath "/albums/$albumid/user/$PSItem" -ImmichSession:$Session -Body:$BodyParameters
        }
    }
}
#endregion
