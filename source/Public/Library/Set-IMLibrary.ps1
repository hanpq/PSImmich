function Set-IMLibrary
{
    <#
    .DESCRIPTION
        Updates an Immich library
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines library to update
    .PARAMETER exclusionPatterns
        Defines exclusion patterns
    .PARAMETER importPaths
        Defines import paths
    .PARAMETER isVisible
        Defines if the library should be visible
    .PARAMETER name
        Defines the name of the library
    .EXAMPLE
        Set-IMLibrary -id <libraryid> -Name 'NewName'

        Update an Immich library
    #>

    [CmdletBinding(SupportsShouldProcess)]
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
        $importPaths,

        [Parameter()]
        [boolean]
        $isVisible,

        [Parameter()]
        [string]
        $name
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'exclusionPatterns', 'importPaths', 'isVisible', 'name')
    }

    PROCESS
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Update'))
            {
                InvokeImmichRestMethod -Method PUT -RelativePath "/libraries/$PSItem" -ImmichSession:$Session -Body:$BodyParameters
            }
        }
    }
}
#endregion
