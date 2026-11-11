function Get-IMWorkflow
{
    <#
    .SYNOPSIS
        Retrieves Immich workflows
    .DESCRIPTION
        Retrieves one or more workflows from the Immich server. Can retrieve all workflows or a specific workflow by ID.
        Note: Workflow functionality is in Alpha state as of Immich v2.3.1.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of a specific workflow to retrieve. Accepts pipeline input.
    .PARAMETER Name
        Filters the workflow list by name. Only applies to the list parameter set.
    .PARAMETER Description
        Filters the workflow list by description. Only applies to the list parameter set.
    .PARAMETER Enabled
        Filters the workflow list by enabled state. Only applies to the list parameter set.
    .PARAMETER Logging
        Filters the workflow list by whether run results are logged. Only applies to the list parameter set.
    .PARAMETER Trigger
        Filters the workflow list by trigger type, including AssetOcrExtraction. Only applies to the list parameter set.
    .PARAMETER Share
        Retrieves the shareable representation of the workflow specified by Id instead of the workflow itself.
    .EXAMPLE
        Get-IMWorkflow

        Retrieves all workflows available to the current user.
    .EXAMPLE
        Get-IMWorkflow -Trigger 'AssetCreate' -Enabled:$true

        Retrieves enabled workflows that run when an asset is created.
    .EXAMPLE
        Get-IMWorkflow -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Share

        Retrieves the shareable representation of a workflow.
    .EXAMPLE
        Get-IMWorkflow -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retrieves a specific workflow by its ID.
    .EXAMPLE
        'workflow1-uuid', 'workflow2-uuid' | Get-IMWorkflow

        Retrieves multiple workflows by piping their IDs.
    .NOTES
        This feature is in Alpha state and may be subject to changes in future Immich versions.
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(ParameterSetName = 'list')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'list')]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'list')]
        [bool]
        $Enabled,

        [Parameter(ParameterSetName = 'list')]
        [bool]
        $Logging,

        [Parameter(ParameterSetName = 'list')]
        [ValidateSet('AssetCreate', 'AssetMetadataExtraction', 'AssetOcrExtraction', 'AssetTagged')]
        [string]
        $Trigger,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter(ParameterSetName = 'id')]
        [switch]
        $Share
    )

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                $ApiParams = @{ ImmichSession = $Session }
                if ($PSBoundParameters.ContainsKey('Name')) { $ApiParams.Name = $Name }
                if ($PSBoundParameters.ContainsKey('Description')) { $ApiParams.Description = $Description }
                if ($PSBoundParameters.ContainsKey('Trigger')) { $ApiParams.Trigger = $Trigger }
                # The server rejects boolean query values for enabled and logging, so those filters are applied to the returned workflows.
                Invoke-ImmichApiSearchWorkflows @ApiParams |
                    ForEach-Object { [WorkflowResponseDto]::new($PSItem) } |
                    Where-Object {
                        (-not $PSBoundParameters.ContainsKey('Enabled') -or $PSItem.enabled -eq $Enabled) -and
                        (-not $PSBoundParameters.ContainsKey('Logging') -or $PSItem.logging -eq $Logging)
                    }
            }
            'id'
            {
                if ($Share)
                {
                    Invoke-ImmichApiGetWorkflowForShare -Id $Id -ImmichSession $Session | ForEach-Object { [WorkflowShareResponseDto]::new($PSItem) }
                }
                else
                {
                    Invoke-ImmichApiGetWorkflow -Id $Id -ImmichSession $Session | ForEach-Object { [WorkflowResponseDto]::new($PSItem) }
                }
            }
        }
    }
}
#endregion
