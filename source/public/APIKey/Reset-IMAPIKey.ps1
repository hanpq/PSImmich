function Reset-IMAPIKey
{
    <#
    .SYNOPSIS
        Generates a new secret for an existing Immich API key
    .DESCRIPTION
        Rotates the secret of one or more API keys that the current user owns. The previous secret stops working
        immediately, so any application using it must be updated with the returned secret.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the API key to rotate. Accepts pipeline input.
    .EXAMPLE
        Reset-IMAPIKey -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Rotates the secret of the specified API key after a confirmation prompt and returns the new secret.
    .EXAMPLE
        Get-IMAPIKey | Where-Object {$_.name -eq 'Automation Script'} | Reset-IMAPIKey -Confirm:$false

        Rotates the secret of the API key named 'Automation Script' without a confirmation prompt.
    .NOTES
        The new API key secret is only displayed once. Store it securely as it cannot be retrieved later.
        This cmdlet supports ShouldProcess and will prompt for confirmation before rotating the key.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id
    )

    process
    {
        if ($PSCmdlet.ShouldProcess($Id, 'Rotate API key secret'))
        {
            Invoke-ImmichApiRotateApiKey -Id $Id -ImmichSession $Session | ForEach-Object { [ApiKeyCreateResponseDto]::new($PSItem) }
        }
    }
}
#endregion
