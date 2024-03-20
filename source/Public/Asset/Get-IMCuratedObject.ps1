function Get-IMCuratedObject
{
    <#
    .DESCRIPTION
        Retreives Immich curated objects
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMCuratedObject

        Retreives Immich curated objects
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/asset/curated-objects' -ImmichSession:$Session

}
#endregion
