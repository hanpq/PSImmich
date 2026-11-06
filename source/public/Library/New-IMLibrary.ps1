function New-IMLibrary
{
    <#
    .SYNOPSIS
        Creates a new Immich library for asset management.
    .DESCRIPTION
        The New-IMLibrary function creates a new library in Immich for organizing and managing
        digital assets. Libraries define collections of assets with specific import paths,
        exclusion patterns, and ownership settings. Each library can monitor designated
        directories and automatically import new assets according to configured rules.

        Libraries provide a way to organize assets from different sources or with different
        access requirements, such as personal photos, family albums, or professional archives.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Name
        Specifies the display name for the new library. This name appears in the Immich
        interface and should clearly identify the library's purpose or content source.
    .PARAMETER ExclusionPatterns
        Defines file and folder patterns to exclude from library scanning. These patterns
        help filter out unwanted files such as system files, temporary files, or specific
        file types that should not be imported as assets.
    .PARAMETER ImportPaths
        Specifies the file system paths that the library should monitor for assets.
        These paths define the directories from which the library will import photos,
        videos, and other supported media files.
    .PARAMETER OwnerId
        Specifies the user ID of the library owner. The owner has administrative control
        over the library settings and can manage access permissions for other users.
    .EXAMPLE
        New-IMLibrary -Name 'Family Photos' -ImportPaths '/mnt/photos/family'

        Creates a new library named 'Family Photos' that monitors the '/mnt/photos/family' directory.
    .EXAMPLE
        New-IMLibrary -Name 'Professional Archive' -ImportPaths @('/storage/work', '/backup/projects') -ExclusionPatterns @('*.tmp', '.*')

        Creates a library with multiple import paths and exclusion patterns for temporary and hidden files.
    .EXAMPLE
        New-IMLibrary -Name 'User Collection' -ImportPaths '/home/user/pictures' -OwnerId 'bf973405-3f2a-48d2-a687-2ed4167164be'

        Creates a library with a specific owner assigned by user ID.
    .EXAMPLE
        $library = New-IMLibrary -Name 'Mobile Uploads' -ImportPaths '/uploads/mobile'
        Write-Output "Created library: $($library.name) with ID: $($library.id)"

        Creates a library and captures the returned library object for further processing.
    .NOTES
        After creating a library, use Sync-IMLibrary to initiate the initial scan and
        import of existing assets from the configured import paths.
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

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)

    }

    process
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/libraries' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
