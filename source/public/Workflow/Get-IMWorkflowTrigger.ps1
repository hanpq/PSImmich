function Get-IMWorkflowTrigger
{
    <#
    .SYNOPSIS
        Retrieves the available Immich workflow triggers
    .DESCRIPTION
        Retrieves the workflow triggers supported by the Immich server, together with the event types each trigger provides.
        Use these trigger names with Get-IMWorkflow, New-IMWorkflow and Set-IMWorkflow.
        Note: Workflow functionality is in Alpha state as of Immich v3.3.6.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .EXAMPLE
        Get-IMWorkflowTrigger

        Lists all workflow triggers supported by the server.
    .NOTES
        This feature is in Alpha state and may be subject to changes in future Immich versions.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    process
    {
        Invoke-ImmichApiGetWorkflowTriggers -ImmichSession $Session | ForEach-Object { [WorkflowTriggerResponseDto]::new($PSItem) }
    }
}
#endregion
