function Get-IMSupportedMediaType
{
    <#
    .SYNOPSIS
        Retrieves supported media file types.
    .DESCRIPTION
        Gets list of media file formats supported by Immich server for import.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Get-IMSupportedMediaType

        Lists supported media file types.
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/media-types' -ImmichSession:$Session

}
#endregion
