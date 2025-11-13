function New-IMLibrary
{
    <#
    .DESCRIPTION
        Adds a new library
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Name
        Defines the name of the library
    .PARAMETER ExclusionPatterns
        Defines an exclusion pattern
    .PARAMETER ImportPaths
        Defines the import paths
    .PARAMETER OwnerId
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
        [ApiParameter('name')]
        [string]
        $Name,

        [Parameter()]
        [ApiParameter('exclusionPatterns')]
        [string[]]
        $ExclusionPatterns,

        [Parameter()]
        [ApiParameter('importPaths')]
        [string[]]
        $ImportPaths,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('ownerId')]
        [string]
        $OwnerId
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)

    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/libraries' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
