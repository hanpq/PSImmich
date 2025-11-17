function Disconnect-Immich
{
    <#
    .SYNOPSIS
        Disconnects from Immich server.
    .DESCRIPTION
        Cleans up session configuration and authentication state.
    .PARAMETER Session
        Specific session to disconnect, or default session if omitted.
    .EXAMPLE
        Disconnect-Immich

        Disconnects from default session.
    .EXAMPLE
        Disconnect-Immich -Session $session

        Disconnects specific session object.
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ImmichSession]
        $Session = $null
    )

    process
    {
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

}
