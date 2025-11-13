function Restore-IMUser
{
    <#
    .SYNOPSIS
        Restores a deleted user account.
    .DESCRIPTION
        Recovers user account from trash within the 7-day retention period.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        User ID to restore from trash.
    .EXAMPLE
        Restore-IMUser -Id 'user-id'

        Restores user from trash.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id
    )


    process
    {
        $id | ForEach-Object {
            InvokeImmichRestMethod -Method POST -RelativePath "/admin/users/$PSItem/restore" -ImmichSession:$Session
        }
    }

}
#endregion
