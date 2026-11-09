function Get-IMPlugin
{
    <#
    .SYNOPSIS
        Retrieves Immich plugins
    .DESCRIPTION
        Retrieves one or more plugins from the Immich server. Can retrieve all plugins, optionally filtered, or a specific plugin by ID.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of a specific plugin to retrieve. Accepts pipeline input.
    .PARAMETER Name
        Filter the plugin list by plugin name.
    .PARAMETER Title
        Filter the plugin list by plugin title.
    .PARAMETER Version
        Filter the plugin list by plugin version.
    .PARAMETER Description
        Filter the plugin list by plugin description.
    .PARAMETER Enabled
        Filter the plugin list by whether the plugin is enabled.
    .EXAMPLE
        Get-IMPlugin

        Retrieves all plugins available to the current user.
    .EXAMPLE
        Get-IMPlugin -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retrieves a specific plugin by its ID.
    .EXAMPLE
        'plugin1-uuid', 'plugin2-uuid' | Get-IMPlugin

        Retrieves multiple plugins by piping their IDs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter(ParameterSetName = 'list')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'list')]
        [string]
        $Title,

        [Parameter(ParameterSetName = 'list')]
        [string]
        $Version,

        [Parameter(ParameterSetName = 'list')]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'list')]
        [bool]
        $Enabled
    )

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                $ApiParams = @{ ImmichSession = $Session }
                foreach ($Filter in 'Name', 'Title', 'Version', 'Description', 'Enabled')
                {
                    if ($PSBoundParameters.ContainsKey($Filter)) { $ApiParams[$Filter] = $PSBoundParameters[$Filter] }
                }
                Invoke-ImmichApiSearchPlugins @ApiParams | ForEach-Object { [PluginResponseDto]::new($PSItem) }
            }
            'id'
            {
                Invoke-ImmichApiGetPlugin -Id $Id -ImmichSession $Session | ForEach-Object { [PluginResponseDto]::new($PSItem) }
            }
        }
    }
}
#endregion
