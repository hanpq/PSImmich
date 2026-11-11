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
    .PARAMETER Trigger
        The trigger for the workflow, including AssetOcrExtraction.
    .PARAMETER Enabled
        Specifies whether the workflow should be enabled or disabled.
    .PARAMETER Logging
        Specifies whether run results of the workflow are logged.
    .PARAMETER Steps
        An array of step hashtables. Each step requires a 'method' and a 'config' hashtable, and may include 'enabled'.
        Replaces all existing steps of the workflow.
    .EXAMPLE
        Set-IMWorkflow -Id 'workflow-uuid' -Description 'Updated workflow for processing new photos'

        Updates the workflow description.
    .EXAMPLE
        Set-IMWorkflow -Id 'workflow-uuid' -Enabled:$false

        Disables the workflow.
    .EXAMPLE
        Set-IMWorkflow -Id 'workflow-uuid' -Name 'New Workflow Name' -Trigger 'AssetTagged'

        Renames the workflow and changes its trigger.
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
        [string]
        $Name,

        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [ValidateSet('AssetCreate', 'AssetMetadataExtraction', 'AssetOcrExtraction', 'AssetTagged')]
        [string]
        $Trigger,

        [Parameter()]
        [bool]
        $Enabled,

        [Parameter()]
        [bool]
        $Logging,

        [Parameter()]
        [hashtable[]]
        $Steps
    )

    process
    {
        $Body = @{}
        if ($PSBoundParameters.ContainsKey('Name')) { $Body.name = $Name }
        if ($PSBoundParameters.ContainsKey('Description')) { $Body.description = $Description }
        if ($PSBoundParameters.ContainsKey('Trigger')) { $Body.trigger = $Trigger }
        if ($PSBoundParameters.ContainsKey('Enabled')) { $Body.enabled = $Enabled }
        if ($PSBoundParameters.ContainsKey('Logging')) { $Body.logging = $Logging }
        if ($PSBoundParameters.ContainsKey('Steps')) { $Body.steps = @($Steps) }

        # We loop through IDs because ids can be provided as an array to the parameter in which case the process block only gets called once.
        $Id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'UPDATE'))
            {
                Invoke-ImmichApiUpdateWorkflow -Id $CurrentID -Body $Body -ImmichSession $Session | ForEach-Object { [WorkflowResponseDto]::new($PSItem) }
            }
        }
    }
}
#endregion
