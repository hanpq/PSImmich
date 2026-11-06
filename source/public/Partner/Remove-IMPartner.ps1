function Remove-IMPartner
{
    <#
    .SYNOPSIS
        Removes a sharing partner.
    .DESCRIPTION
        Ends partnership relationship and stops asset sharing with specified user.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Partner user ID to remove. Must be valid GUID format.
    .EXAMPLE
        Remove-IMPartner -Id 'bf973405-3f2a-48d2-a687-2ed4167164be'

        Removes the specified partner relationship.
    .NOTES
        Supports -WhatIf and -Confirm for safety.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $id
    )
    if ($PSCmdlet.ShouldProcess($id, 'DELETE'))
    {
        InvokeImmichRestMethod -Method DELETE -RelativePath "/partners/$id" -ImmichSession:$Session
    }
}
#endregion
