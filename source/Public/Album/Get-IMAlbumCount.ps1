function Get-IMAlbumCount
{
    <#
    .DESCRIPTION
        Retreives album count
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMAlbumCount

        Retreives album count
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/album/count' -ImmichSession:$Session

}
#endregion
