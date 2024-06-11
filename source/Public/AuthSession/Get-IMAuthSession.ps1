function Get-IMAuthSession
{
    <#
    .DESCRIPTION
        Get authenticated sessions
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMAuthDevice

        Get authorized devices
    .NOTES
        Due to Get-IMSession already being used by the PSImmich module, cmdlets within the session namespace is prefixed with "Auth".
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
