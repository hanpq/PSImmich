function Test-IMPing
{
    <#
    .DESCRIPTION
        Ping Immich instance
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Test-IMPing

        Ping Immich instance
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    $Result = InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server-info/ping' -ImmichSession:$Session
    if ($Result.res -eq 'pong')
    {
        return [pscustomobject]@{responds = $true }
    }
    else
    {
        return [pscustomobject]@{responds = $false }
    }

}
#endregion
