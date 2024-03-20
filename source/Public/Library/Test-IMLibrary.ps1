function Test-IMLibrary
{
    <#
    .DESCRIPTION
        Validate library
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines libraries to validate
    .PARAMETER exclusionPatterns
        Defines exlusion patterns
    .PARAMETER importPaths
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
        $id,

        [Parameter()]
        [string[]]
        $exclusionPatterns,

        [Parameter()]
        [string[]]
        $importPaths
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'exclusionPatterns', 'importPaths')
    }

    PROCESS
    {
        $id | ForEach-Object {
            InvokeImmichRestMethod -Method POST -RelativePath "/library/$PSItem/validate" -ImmichSession:$Session -Body:$BodyParameters
        }
    }
}
#endregion
