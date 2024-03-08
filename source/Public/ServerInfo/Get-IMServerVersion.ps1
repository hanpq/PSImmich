function Get-IMServerVersion
{
    <#
    .DESCRIPTION
        Retreives Immich server version
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMServerVersion

        Retreives Immich server version
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    $Result = InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server-info/version' -ImmichSession:$Session
    return [pscustomobject]@{
        version = "$($Result.Major).$($Result.Minor).$($Result.Patch)"
    }

}
#endregion
