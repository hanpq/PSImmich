﻿function Get-IMCuratedLocation
{
    <#
    .DESCRIPTION
        Retreives Immich curated locations
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMCuratedLocation

        Retreives Immich curated locations
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/asset/curated-locations' -ImmichSession:$Session

}
#endregion
