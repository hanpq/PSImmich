function Test-IMLibrary
{
    <#
    .SYNOPSIS
        Validates an Immich library configuration.
    .DESCRIPTION
        The Test-IMLibrary function validates the configuration of an Immich library by checking
        the accessibility and validity of import paths, exclusion patterns, and other settings.
        This validation helps ensure that library configurations are correct and that the
        specified paths are accessible to the Immich server.

        The function can validate multiple libraries simultaneously and supports pipeline input
        for batch validation operations. Validation results indicate whether the library
        configuration is valid and highlight any potential issues.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Specifies the unique identifier(s) of the library to validate. Must be valid GUID format.
        Accepts pipeline input by value and by property name for batch validation operations.
    .PARAMETER ExclusionPatterns
        Specifies file and folder exclusion patterns to validate. These patterns are checked
        for syntax correctness and potential conflicts with import paths.
    .PARAMETER ImportPaths
        Specifies the import paths to validate. The function checks whether these paths
        are accessible to the Immich server and properly configured for asset importing.
    .EXAMPLE
        Test-IMLibrary -Id 'bf973405-3f2a-48d2-a687-2ed4167164be'

        Validates the library configuration for the specified library ID.
    .EXAMPLE
        Test-IMLibrary -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -ImportPaths @('/photos', '/videos')

        Validates the library and specifically tests the accessibility of the provided import paths.
    .EXAMPLE
        Get-IMLibrary | Test-IMLibrary

        Validates all libraries by processing library objects from the pipeline.
    .EXAMPLE
        Test-IMLibrary -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -ExclusionPatterns @('*.tmp', '.*')

        Validates the library configuration and tests specific exclusion patterns for correctness.
    .NOTES
        Library validation helps identify configuration issues before they affect import operations.
        Regular validation is recommended when modifying library settings or server configurations.
    #>

    [CmdletBinding()]
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
        $ImportPaths
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        $Id | ForEach-Object {
            InvokeImmichRestMethod -Method POST -RelativePath "/libraries/$PSItem/validate" -ImmichSession:$Session -Body:$BodyParameters
        }
    }
}
#endregion
