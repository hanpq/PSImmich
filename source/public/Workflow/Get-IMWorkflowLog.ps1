function Get-IMWorkflowLog
{
    <#
    .SYNOPSIS
        Retrieves run logs of an Immich workflow
    .DESCRIPTION
        Retrieves the log entries recording past runs of a workflow. Logs are only written for workflows with logging enabled.
        Note: Workflow functionality is in Alpha state as of Immich v3.3.6.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the workflow whose logs to retrieve. Accepts pipeline input.
    .PARAMETER Before
        Only return log entries recorded before this date and time.
    .PARAMETER Limit
        The maximum number of log entries to return.
    .PARAMETER Result
        Only return log entries with the specified result.
    .EXAMPLE
        Get-IMWorkflowLog -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retrieves all log entries for the specified workflow.
    .EXAMPLE
        Get-IMWorkflowLog -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Result 'error' -Limit 10

        Retrieves the ten most recent failed runs of the workflow.
    .NOTES
        This feature is in Alpha state and may be subject to changes in future Immich versions.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter()]
        [datetime]
        $Before,

        [Parameter()]
        [int]
        $Limit,

        [Parameter()]
        [ValidateSet('completed', 'halted', 'error')]
        [string]
        $Result
    )

    process
    {
        $ApiParams = @{
            Id            = $Id
            ImmichSession = $Session
        }
        if ($PSBoundParameters.ContainsKey('Before')) { $ApiParams.Before = $Before }
        if ($PSBoundParameters.ContainsKey('Limit')) { $ApiParams.Limit = $Limit }
        if ($PSBoundParameters.ContainsKey('Result')) { $ApiParams.Result = $Result }

        Invoke-ImmichApiGetWorkflowLogs @ApiParams | ForEach-Object { [WorkflowLogEntryDto]::new($PSItem) }
    }
}
#endregion
