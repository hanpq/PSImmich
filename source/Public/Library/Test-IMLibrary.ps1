function Test-IMLibrary
{
    <#
    .DESCRIPTION
        Validate library
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Defines libraries to validate
    .PARAMETER ExclusionPatterns
        Defines exlusion patterns
    .PARAMETER ImportPaths
        Defines import paths
    .EXAMPLE
        Test-IMLibrary -id <libraryid>

       Validate library
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

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    PROCESS
    {
        $Id | ForEach-Object {
            InvokeImmichRestMethod -Method POST -RelativePath "/libraries/$PSItem/validate" -ImmichSession:$Session -Body:$BodyParameters
        }
    }
}
#endregion
