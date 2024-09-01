function Get-IMSupportedMediaType
{
    <#
    .DESCRIPTION
        Retreives Immich supported media type
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMSupportedMediaType

        Retreives Immich supported media type
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/media-types' -ImmichSession:$Session

}
#endregion
