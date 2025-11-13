function Remove-IMAPIKey
{
    <#
    .SYNOPSIS
        Removes Immich API keys
    .DESCRIPTION
        Removes one or more API keys from the Immich server. This action is permanent and cannot be undone.
        Any applications using the removed API keys will lose access immediately.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the API key(s) to remove. Accepts pipeline input and multiple values.
    .EXAMPLE
        Remove-IMAPIKey -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Removes the specified API key with confirmation prompt.
    .EXAMPLE
        Get-IMAPIKey | Where-Object {$_.name -like 'Old*'} | Remove-IMAPIKey

        Removes all API keys with names starting with 'Old'.
    .EXAMPLE
        Remove-IMAPIKey -Id 'key-uuid' -Confirm:$false

        Removes the API key without confirmation prompt.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing API keys.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id
    )

    process
    {
        $Id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'DELETE'))
            {
                InvokeImmichRestMethod -Method DELETE -RelativePath "/api-keys/$CurrentID" -ImmichSession:$Session
            }
        }
    }

}
#endregion
