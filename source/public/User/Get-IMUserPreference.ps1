function Get-IMUserPreference
{
    <#
    .SYNOPSIS
        Retrieves user preferences.
    .DESCRIPTION
        Gets user interface and behavior preferences for a specific user.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        User ID to get preferences for.
    .EXAMPLE
        Get-IMUserPreference -Id 'user-id'

        Gets user preferences.
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

    process
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
