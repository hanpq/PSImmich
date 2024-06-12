function Remove-IMAuthSession
{
    <#
    .DESCRIPTION
        Remove one or many auth sessions. Not that if id is not specified all but the current auth session will be purged.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a uuid of an auth session that should be removed
    .EXAMPLE
        Remove-IMAuthSession

        Remove all auth session (except current)
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

    PROCESS
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
