function Get-IMPluginMethod
{
    <#
    .SYNOPSIS
        Retrieves Immich plugin methods
    .DESCRIPTION
        Retrieves the plugin methods available on the Immich server. Methods are the actions that installed plugins expose for use in workflows. The list can be filtered by name, plugin, trigger and workflow type.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        Filter the method list by plugin method ID (UUID).
    .PARAMETER Name
        Filter the method list by method name.
    .PARAMETER Title
        Filter the method list by method title.
    .PARAMETER Description
        Filter the method list by method description.
    .PARAMETER PluginName
        Filter the method list by the name of the plugin that provides the method.
    .PARAMETER PluginVersion
        Filter the method list by the version of the plugin that provides the method.
    .PARAMETER Trigger
        Filter the method list by workflow trigger.
    .PARAMETER Type
        Filter the method list by workflow type. Applied after the list is retrieved, against each method's types.
    .EXAMPLE
        Get-IMPluginMethod

        Retrieves all plugin methods available to the current user.
    .EXAMPLE
        Get-IMPluginMethod -Trigger 'AssetCreate'

        Retrieves the plugin methods that can be used in workflows triggered by asset creation.
    .EXAMPLE
        Get-IMPluginMethod -PluginName 'my-plugin' -Type 'AssetV1'

        Retrieves the AssetV1 methods provided by the plugin named 'my-plugin'.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [string]
        $PluginName,

        [Parameter()]
        [string]
        $PluginVersion,

        [Parameter()]
        [ValidateSet('AssetCreate', 'AssetMetadataExtraction', 'AssetTagged')]
        [string]
        $Trigger,

        [Parameter()]
        [ValidateSet('AssetV1')]
        [string]
        $Type
    )

    process
    {
        $ApiParams = @{ ImmichSession = $Session }
        foreach ($Filter in 'Id', 'Name', 'Title', 'Description', 'PluginName', 'PluginVersion', 'Trigger')
        {
            if ($PSBoundParameters.ContainsKey($Filter)) { $ApiParams[$Filter] = $PSBoundParameters[$Filter] }
        }
        # The server returns HTTP 500 for the type query, so the type filter is applied to the returned methods.
        Invoke-ImmichApiSearchPluginMethods @ApiParams |
            ForEach-Object { [PluginMethodResponseDto]::new($PSItem) } |
            Where-Object { -not $PSBoundParameters.ContainsKey('Type') -or $PSItem.types -contains $Type }
    }
}
