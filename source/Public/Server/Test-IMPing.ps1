function Test-IMPing
{
    <#
    .SYNOPSIS
        Tests connectivity to Immich server.
    .DESCRIPTION
        Verifies server availability and response by sending a ping request.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Test-IMPing

        Tests connectivity to the current Immich instance.
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    $Result = InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/ping' -ImmichSession:$Session
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
