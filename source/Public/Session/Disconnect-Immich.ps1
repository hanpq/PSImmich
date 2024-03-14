function Disconnect-Immich
{
    <#
    .DESCRIPTION
        Disconnect and cleanup session configuration
    .PARAMETER Session
        Defines a ImmichSession object that will be disconnected and cleaned up.
    .EXAMPLE
        Disconnect-Immich

        Disconnect from the default immich session
    .EXAMPLE
        Disconnect-Immich -Session $Session

        Disconnect the specified session
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method Post -RelativePath '/auth/logout' -ImmichSession:$Session

    # Remove ImmichSession variable
    if ($Session)
    {
        if ($script:ImmichSession.SessionID -eq $Session.SessionID)
        {
            Remove-Variable ImmichSession -Scope Script
        }
    }
    else
    {
        Remove-Variable ImmichSession -Scope Script
    }

}
