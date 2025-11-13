function Get-IMAuthSession
{
    <#
    .SYNOPSIS
        Retrieves authenticated sessions from Immich
    .DESCRIPTION
        Retrieves information about all currently active authenticated sessions in Immich. This includes
        sessions from web browsers, mobile apps, and API clients.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .EXAMPLE
        Get-IMAuthSession

        Retrieves all active authenticated sessions.
    .EXAMPLE
        $sessions = Get-IMAuthSession
        $sessions | Where-Object {$_.deviceType -eq 'mobile'}

        Retrieves sessions and filters for mobile device sessions.
    .EXAMPLE
        Get-IMAuthSession | Format-Table deviceType, createdAt, current

        Displays session information in a formatted table.
    .NOTES
        Due to Get-IMSession already being used by the PSImmich module, cmdlets within the session namespace are prefixed with 'Auth'.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    InvokeImmichRestMethod -Method GET -RelativePath '/sessions' -ImmichSession:$Session
}
#endregion
