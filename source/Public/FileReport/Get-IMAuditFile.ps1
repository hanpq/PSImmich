function Get-IMAuditFile
{
    <#
    .DESCRIPTION
        Retreives Immich audit files
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMAuditFile

        Retreives Immich audit files
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/reports' -ImmichSession:$Session

}
#endregion
