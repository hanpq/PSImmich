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
    .PARAMETER Trigger
        The trigger for the workflow. This determines when the workflow will be executed. Required by the Immich API.
    .PARAMETER Enabled
        Specifies whether the workflow should be enabled upon creation. Defaults to true.
    .PARAMETER Logging
        Specifies whether run results of the workflow are logged.
    .PARAMETER Steps
        An array of step hashtables. Each step requires a 'method' (plugin method name) and a 'config' hashtable,
        and may include 'enabled' (boolean).
    .EXAMPLE
        New-IMWorkflow -Name 'Auto Tag Photos' -Trigger 'AssetCreate' -Description 'Automatically tag uploaded photos'

        Creates a new workflow with basic information.
    .EXAMPLE
        New-IMWorkflow -Name 'Process Videos' -Trigger 'AssetTagged' -Enabled:$false

        Creates a new workflow that is initially disabled.
    .NOTES
        This feature is in Alpha state and may be subject to changes in future Immich versions.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Description,

        [Parameter(Mandatory)]
        [ValidateSet('AssetCreate', 'AssetMetadataExtraction', 'AssetTagged')]
        [string]
        $Trigger,

        [Parameter()]
        [bool]
        $Enabled = $true,

        [Parameter()]
        [bool]
        $Logging,

        [Parameter()]
        [hashtable[]]
        $Steps
    )

    $Body = @{
        name    = $Name
        trigger = $Trigger
        enabled = $Enabled
    }
    if ($PSBoundParameters.ContainsKey('Description')) { $Body.description = $Description }
    if ($PSBoundParameters.ContainsKey('Logging')) { $Body.logging = $Logging }
    if ($PSBoundParameters.ContainsKey('Steps')) { $Body.steps = @($Steps) }

    Invoke-ImmichApiCreateWorkflow -Body $Body -ImmichSession $Session | ForEach-Object { [WorkflowResponseDto]::new($PSItem) }
}
#endregion
