function Get-IMPlugin
{
    <#
    .SYNOPSIS
        Retrieves Immich plugins
    .DESCRIPTION
        Retrieves one or more plugins from the Immich server. Can retrieve all plugins or a specific plugin by ID.
        Note: Plugin functionality is in Alpha state as of Immich v2.3.1.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of a specific plugin to retrieve. Accepts pipeline input.
    .EXAMPLE
        Get-IMPlugin

        Retrieves all plugins available to the current user.
    .EXAMPLE
        Get-IMPlugin -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retrieves a specific plugin by its ID.
    .EXAMPLE
        'plugin1-uuid', 'plugin2-uuid' | Get-IMPlugin

        Retrieves multiple plugins by piping their IDs.
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
                InvokeImmichRestMethod -Method Get -RelativePath '/plugins' -ImmichSession:$Session | AddCustomType IMPlugin
            }
            'id'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/plugins/$Id" -ImmichSession:$Session | AddCustomType IMPlugin
            }
        }
    }
}
#endregion
