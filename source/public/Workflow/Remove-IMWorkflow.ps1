function Remove-IMWorkflow
{
    <#
    .SYNOPSIS
        Removes Immich workflows
    .DESCRIPTION
        Removes one or more workflows from the Immich server. This action is permanent and cannot be undone.
        Note: Workflow functionality is in Alpha state as of Immich v2.3.1.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the workflow(s) to remove. Accepts pipeline input and multiple values.
    .EXAMPLE
        Remove-IMWorkflow -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Removes the specified workflow with confirmation prompt.
    .EXAMPLE
        Get-IMWorkflow | Where-Object { $_.name -like 'temp*' } | Remove-IMWorkflow

        Removes all workflows with names starting with 'temp'.
    .EXAMPLE
        Remove-IMWorkflow -Id 'workflow-uuid' -Confirm:$false

        Removes the workflow without confirmation prompt.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing workflows.
        This feature is in Alpha state and may be subject to changes in future Immich versions.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('WorkflowId')]
        [string[]]
        $Id
    )

    process
    {
        # We loop through IDs because ids can be provided as an array to the parameter in which case the process block only gets called once.
        $Id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'DELETE'))
            {
                InvokeImmichRestMethod -Method Delete -RelativePath "/workflows/$CurrentID" -ImmichSession:$Session
            }
        }
    }
}
#endregion
