function Get-IMServerVersion
{
    <#
    .DESCRIPTION
        Retreives Immich server version
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER History
        Defines that version history should be return instead of the current version
    .EXAMPLE
        Get-IMServerVersion

        Retreives Immich server version
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null,

        [Parameter()][switch]$History
    )

    if ($History) {
        $Result = InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/version-history' -ImmichSession:$Session
        return $Result
    }
    else {
        $Result = InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/version' -ImmichSession:$Session
        return [pscustomobject]@{
            version = "$($Result.Major).$($Result.Minor).$($Result.Patch)"
        }
    }

}
#endregion
