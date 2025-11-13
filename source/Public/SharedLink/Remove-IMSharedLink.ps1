function Remove-IMSharedLink
{
    <#
    .SYNOPSIS
        Removes a shared link.
    .DESCRIPTION
        Deletes shared link and revokes external access to associated assets.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Shared link ID to remove.
    .EXAMPLE
        Remove-IMSharedLink -Id 'link-id'

        Removes shared link and revokes access.
    .NOTES
        Supports -WhatIf and -Confirm for safety.
    #>

    [CmdletBinding(SupportsShouldProcess)]
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
            if ($PSCmdlet.ShouldProcess($PSItem, 'DELETE'))
            {
                InvokeImmichRestMethod -Method DELETE -RelativePath "/shared-links/$PSItem" -ImmichSession:$Session
            }
        }
    }
}
#endregion
