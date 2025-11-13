function Get-IMUser
{
    <#
    .SYNOPSIS
        Retrieves Immich users.
    .DESCRIPTION
        Gets user accounts and profile information from Immich server.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Specific user ID to retrieve.
    .PARAMETER IncludeDeleted
        Include deleted users in results.
    .PARAMETER Me
        Retrieve current user's information.
    .EXAMPLE
        Get-IMUser -Me

        Gets current user information.
    .EXAMPLE
        Get-IMUser -Id 'user-id'

        Gets specific user details.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP, evaluated as part of parameterset check')]
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id,

        [Parameter(ParameterSetName = 'list')]
        [switch]
        $IncludeDeleted,

        [Parameter(Mandatory, ParameterSetName = 'me')]
        [switch]
        $Me
    )

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                if ($IncludeDeleted)
                {
                    InvokeImmichRestMethod -Method Get -RelativePath '/admin/users' -ImmichSession:$Session -Query:@{withDeleted = $true } | AddCustomType IMUser
                }
                else
                {
                    InvokeImmichRestMethod -Method Get -RelativePath '/admin/users' -ImmichSession:$Session | AddCustomType IMUser
                }
            }
            'id'
            {
                $id | ForEach-Object {
                    InvokeImmichRestMethod -Method Get -RelativePath "/admin/users/$PSItem" -ImmichSession:$Session | AddCustomType IMUser
                }
            }
            'me'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/users/me' -ImmichSession:$Session | AddCustomType IMUser
            }
        }
    }
}
#endregion
