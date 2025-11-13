function Get-IMSession
{
    <#
    .SYNOPSIS
        Displays current Immich session information.
    .DESCRIPTION
        Shows active session details including server URL and authentication status.
    .PARAMETER Session
        Specific session to display, or default session if omitted.
    .EXAMPLE
        Get-IMSession

        Shows current session information.
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    if ($Session)
    {
        Write-Debug -Message 'Get-PSession; ImmichSession was passed as parameter'
        return $Session
    }
    elseif ($script:ImmichSession)
    {
        Write-Debug -Message 'Get-PSession; ImmichSession found in script scope'
        return $script:ImmichSession
    }
    else
    {
        Write-Error -Message 'No Immich Session established, please call Connect-Immich'
    }
}
#endregion
