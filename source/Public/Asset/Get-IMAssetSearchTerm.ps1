﻿function Get-IMAssetSearchTerm
{
    <#
    .DESCRIPTION
        Retreives search terms
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMAssetSearchTerm

        Retreives search terms
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    PROCESS
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/asset/search-terms' -ImmichSession:$Session
    }
}
#endregion
