function Get-IMServerVersion
{
    <#
    .SYNOPSIS
        Retrieves Immich server version information.
    .DESCRIPTION
        Gets current server version or version history details.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER History
        Returns version history instead of current version when specified.
    .EXAMPLE
        Get-IMServerVersion

        Gets current server version.
    .EXAMPLE
        Get-IMServerVersion -History

        Gets server version history.
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null,

        [Parameter()][switch]$History
    )

    if ($History)
    {
        $Result = InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/version-history' -ImmichSession:$Session
        return $Result
    }
    else
    {
        $Result = InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/version' -ImmichSession:$Session
        return [pscustomobject]@{
            version = "$($Result.Major).$($Result.Minor).$($Result.Patch)"
        }
    }

}
#endregion
