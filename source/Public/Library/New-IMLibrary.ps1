function New-IMLibrary
{
    <#
    .DESCRIPTION
        Adds a new library
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER name
        Defines the name of the library
    .PARAMETER exclusionPatterns
        Defines an exclusion pattern
    .PARAMETER importPaths
        Defines the import paths
    .PARAMETER ownerId
        Defines the owner of library
    .EXAMPLE
        New-IMLibrary -Name 'NAS' -ImportPaths '/mnt/media/pictures'

        Adds a new library
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [string]
        $name,

        [Parameter()]
        [string[]]
        $exclusionPatterns,

        [Parameter()]
        [string[]]
        $importPaths,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $ownerId
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'name', 'exclusionPatterns', 'importPaths', 'isVisible', 'isWatched', 'ownerId', 'type')

    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/libraries' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
