function Remove-IMPasskey
{
    <#
    .SYNOPSIS
        Removes passkeys from the current user.
    .DESCRIPTION
        Permanently deletes passkeys. Requires the passkey.delete permission.
        Ensure another sign-in method remains available before removing a passkey.
    .PARAMETER Session
        Optional Immich session to use instead of the default session.
    .PARAMETER Id
        UUIDs of passkeys to remove. Accepts values or objects from the pipeline.
    .EXAMPLE
        Remove-IMPasskey -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Removes the specified passkey after confirmation.
    .EXAMPLE
        Get-IMPasskey -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' | Remove-IMPasskey -WhatIf

        Shows what would be removed without deleting the passkey.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id
    )

    process
    {
        foreach ($CurrentId in $Id)
        {
            if ($PSCmdlet.ShouldProcess($CurrentId, 'Remove passkey'))
            {
                Invoke-ImmichApiDeletePasskey -Id $CurrentId -ImmichSession $Session
            }
        }
    }
}
