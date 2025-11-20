function New-IMWorkflow
{
    <#
    .SYNOPSIS
        Creates a new Immich workflow
    .DESCRIPTION
        Creates a new workflow in Immich with the specified name and configuration. Workflows can be created with
        empty filters and actions and configured later. Note: Workflow functionality is in Alpha state as of Immich v2.3.1.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Name
        The name for the new workflow. This will be displayed in the Immich interface.
    .PARAMETER Description
        A description for the workflow to provide additional context about its purpose.
    .PARAMETER TriggerType
        The trigger type for the workflow. This determines when the workflow will be executed.
    .PARAMETER Enabled
        Specifies whether the workflow should be enabled upon creation. Defaults to true.
    .PARAMETER Actions
        An array of workflow action objects that define what the workflow will do when triggered.
    .PARAMETER Filters
        An array of workflow filter objects that define the conditions for workflow execution.
    .EXAMPLE
        New-IMWorkflow -Name 'Auto Tag Photos' -Description 'Automatically tag uploaded photos'

        Creates a new workflow with basic information.
    .EXAMPLE
        New-IMWorkflow -Name 'Process Videos' -TriggerType 'upload' -Enabled:$false

        Creates a new workflow that is initially disabled.
    .NOTES
        This feature is in Alpha state and may be subject to changes in future Immich versions.
        Workflows can be created with empty filters and actions for later configuration.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
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
        $Enabled = $true,

        [Parameter()]
        [ApiParameter('actions')]
        [hashtable[]]
        $Actions = @(),

        [Parameter()]
        [ApiParameter('filters')]
        [hashtable[]]
        $Filters = @()
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/workflows' -ImmichSession:$Session -Body $BodyParameters | AddCustomType IMWorkflow
    }
}
#endregion
