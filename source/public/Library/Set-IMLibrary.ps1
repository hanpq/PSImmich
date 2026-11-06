function Set-IMLibrary
{
    <#
    .SYNOPSIS
        Updates an Immich library configuration.
    .DESCRIPTION
        The Set-IMLibrary function updates an existing Immich library with new configuration settings.
        You can modify the library name, visibility, import paths, and exclusion patterns.
        This function supports pipeline input for batch updates and includes confirmation prompts
        for safety when making changes to library configurations.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Specifies the unique identifier of the library to update. Must be a valid GUID format.
        Accepts pipeline input by value and by property name for batch operations.
    .PARAMETER ExclusionPatterns
        Defines file and folder exclusion patterns for the library. These patterns determine which
        files and directories should be ignored during library scanning operations.
    .PARAMETER ImportPaths
        Specifies the file system paths that the library should monitor and import assets from.
        Multiple paths can be specified for comprehensive coverage.
    .PARAMETER IsVisible
        Controls whether the library is visible in the Immich interface. Set to $true to make
        the library visible, or $false to hide it from the user interface.
    .PARAMETER Name
        Specifies the new display name for the library. This name appears in the Immich interface
        and helps identify the library's purpose or content type.
    .EXAMPLE
        Set-IMLibrary -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -Name 'Family Photos'

        Updates the library with the specified ID to have the name 'Family Photos'.
    .EXAMPLE
        Set-IMLibrary -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -IsVisible $false

        Hides the specified library from the Immich interface by setting visibility to false.
    .EXAMPLE
        $library | Set-IMLibrary -Name 'Updated Library' -ImportPaths @('/photos', '/videos')

        Updates a library object from the pipeline with a new name and import paths.
    .EXAMPLE
        Get-IMLibrary | Where-Object Name -like '*temp*' | Set-IMLibrary -IsVisible $false

        Hides all libraries with 'temp' in their name using pipeline processing.
    .NOTES
        This function supports ShouldProcess for confirmation prompts when making changes.
        Use -WhatIf to preview changes before applying them to library configurations.
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
        [ApiParameter('exclusionPatterns')]
        [string[]]
        $ExclusionPatterns,

        [Parameter()]
        [ApiParameter('importPaths')]
        [string[]]
        $ImportPaths,

        [Parameter()]
        [ApiParameter('name')]
        [string]
        $Name
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        $Id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Update'))
            {
                InvokeImmichRestMethod -Method PUT -RelativePath "/libraries/$PSItem" -ImmichSession:$Session -Body:$BodyParameters
            }
        }
    }
}
#endregion
