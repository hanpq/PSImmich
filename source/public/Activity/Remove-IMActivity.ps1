function Remove-IMActivity
{
    <#
    .SYNOPSIS
        Removes an activity from an Immich album
    .DESCRIPTION
        Removes a specific activity (comment or like) from an Immich album. This action is permanent and cannot be undone.
        Supports confirmation prompts through ShouldProcess.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the activity to remove. Accepts pipeline input.
    .EXAMPLE
        Remove-IMActivity -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Removes the specified activity with confirmation prompt.
    .EXAMPLE
        Remove-IMActivity -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Confirm:$false

        Removes the specified activity without confirmation prompt.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing activities.
    #>

    [CmdletBinding(SupportsShouldProcess)]
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
        if ($PSCmdlet.ShouldProcess($Id, 'DELETE'))
        {
            InvokeImmichRestMethod -Method DELETE -RelativePath "/activities/$Id" -ImmichSession:$Session
        }
    }

}
#endregion
