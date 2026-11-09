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
        Invoke-ImmichApiLogout -ImmichSession $Session

        # Remove ImmichSession variable when it exists and matches the disconnected session
        $defaultSession = Get-Variable -Name ImmichSession -Scope Script -ValueOnly -ErrorAction SilentlyContinue
        if ($null -eq $defaultSession)
        {
            return
        }

        if (-not $Session -or $defaultSession.SessionID -eq $Session.SessionID)
        {
            Remove-Variable -Name ImmichSession -Scope Script -ErrorAction SilentlyContinue
        }
    }

}
