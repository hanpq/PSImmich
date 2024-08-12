function Get-IMUserPreference
{
    <#
    .DESCRIPTION
        Retreives Immich user preference
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific user id to be retreived
    .EXAMPLE
        Get-IMUserPreference -id <userid>

        Retreives Immich user preferences
    .EXAMPLE
        Get-IMUserPreference

        Retrevies Immich user preferences for the currently logged in user
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP, evaluated as part of parameterset check')]
    [CmdletBinding(DefaultParameterSetName = 'me')]
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
        switch ($PSCmdlet.ParameterSetName)
        {
            'id'
            {
                $id | ForEach-Object {
                    InvokeImmichRestMethod -Method Get -RelativePath "/admin/users/$PSItem/preferences" -ImmichSession:$Session | AddCustomType IMUserPreference
                }
            }
            'me'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/users/me/preferences' -ImmichSession:$Session | AddCustomType IMUserPreference
            }
        }
    }
}
#endregion
