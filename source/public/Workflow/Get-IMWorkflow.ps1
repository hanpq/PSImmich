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
    .EXAMPLE
        Get-IMWorkflow

        Retrieves all workflows available to the current user.
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

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id
    )

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/workflows' -ImmichSession:$Session | AddCustomType IMWorkflow
            }
            'id'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/workflows/$Id" -ImmichSession:$Session | AddCustomType IMWorkflow
            }
        }
    }
}
#endregion
