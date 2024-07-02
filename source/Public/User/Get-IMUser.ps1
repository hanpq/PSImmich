function Get-IMUser
{
    <#
    .DESCRIPTION
        Retreives Immich user
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific user id to be retreived
    .PARAMETER IncludeDeleted
        Defines if deleted users should be returned.
    .PARAMETER Me
        Defines that the currently connected users information is retreived.
    .EXAMPLE
        Get-IMUser -id <userid>

        Retreives Immich user
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

    PROCESS
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
