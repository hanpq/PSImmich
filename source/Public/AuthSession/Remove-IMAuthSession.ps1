function Remove-IMAuthSession
{
    <#
    .SYNOPSIS
        Removes authenticated sessions from Immich
    .DESCRIPTION
        Removes one or more authenticated sessions from Immich. When no specific session ID is provided,
        all sessions except the current one will be removed. This is useful for security purposes or
        when cleaning up old sessions.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of specific authenticated session(s) to remove. Accepts pipeline input and multiple values.
        If not specified, all sessions except the current one will be removed.
    .EXAMPLE
        Remove-IMAuthSession

        Removes all authenticated sessions except the current one with confirmation prompt.
    .EXAMPLE
        Remove-IMAuthSession -Id 'session-uuid'

        Removes a specific authenticated session with confirmation prompt.
    .EXAMPLE
        Get-IMAuthSession | Where-Object {$_.deviceType -eq 'mobile'} | Remove-IMAuthSession

        Removes all mobile device sessions via pipeline.
    .EXAMPLE
        Remove-IMAuthSession -Confirm:$false

        Removes all sessions except current without confirmation prompt.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing sessions.
        The current session cannot be removed and will be preserved even when removing all sessions.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(DefaultParameterSetName = 'list', SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id

    )

    process
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            switch ($PSCmdlet.ParameterSetName)
            {
                'list'
                {
                    if ($PSCmdlet.ShouldProcess('All auth sessions', 'DELETE'))
                    {
                        InvokeImmichRestMethod -Method DELETE -RelativePath '/sessions' -ImmichSession:$Session
                    }
                }
                'id'
                {
                    if ($PSCmdlet.ShouldProcess($CurrentID, 'DELETE'))
                    {
                        InvokeImmichRestMethod -Method DELETE -RelativePath "/sessions/$CurrentID" -ImmichSession:$Session
                    }
                }
            }
        }
    }
}
#endregion
