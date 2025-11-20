function Set-IMWorkflow
{
    <#
    .SYNOPSIS
        Updates an Immich workflow
    .DESCRIPTION
        Updates various properties of an Immich workflow including name, description, trigger type, enabled state,
        filters, and actions. Note: Workflow functionality is in Alpha state as of Immich v2.3.1.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the workflow(s) to update. Accepts pipeline input and multiple values.
    .PARAMETER Name
        The new name for the workflow.
    .PARAMETER Description
        The new description for the workflow.
    .PARAMETER TriggerType
        The trigger type for the workflow. This determines when the workflow will be executed.
    .PARAMETER Enabled
        Specifies whether the workflow should be enabled or disabled.
    .PARAMETER Actions
        An array of workflow action objects that define what the workflow will do when triggered.
    .PARAMETER Filters
        An array of workflow filter objects that define the conditions for workflow execution.
    .EXAMPLE
        Set-IMWorkflow -Id 'workflow-uuid' -Description 'Updated workflow for processing new photos'

        Updates the workflow description.
    .EXAMPLE
        Set-IMWorkflow -Id 'workflow-uuid' -Enabled:$false

        Disables the workflow.
    .EXAMPLE
        Set-IMWorkflow -Id 'workflow-uuid' -Name 'New Workflow Name' -TriggerType 'schedule'

        Renames the workflow and changes its trigger type.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before making changes.
        This feature is in Alpha state and may be subject to changes in future Immich versions.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id,

        [Parameter()]
        [ApiParameter('name')]
        [string]
        $Name,

        [Parameter()]
        [ApiParameter('description')]
        [string]
        $Description,

        [Parameter()]
        [ApiParameter('triggerType')]
        [string]
        $TriggerType,

        [Parameter()]
        [ApiParameter('enabled')]
        [boolean]
        $Enabled,

        [Parameter()]
        [ApiParameter('actions')]
        [hashtable[]]
        $Actions,

        [Parameter()]
        [ApiParameter('filters')]
        [hashtable[]]
        $Filters
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        # We loop through IDs because ids can be provided as an array to the parameter in which case the process block only gets called once.
        $Id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'UPDATE'))
            {
                InvokeImmichRestMethod -Method Put -RelativePath "/workflows/$CurrentID" -ImmichSession:$Session -Body $BodyParameters | AddCustomType IMWorkflow
            }
        }
    }
}
#endregion
