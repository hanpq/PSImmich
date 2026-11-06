function Sync-IMLibrary
{
    <#
    .SYNOPSIS
        Initiates a library synchronization scan job in Immich.
    .DESCRIPTION
        The Sync-IMLibrary function starts a library scan job that synchronizes the Immich library
        with the file system. This process discovers new assets, updates metadata for existing assets,
        and ensures the library reflects the current state of the monitored directories.

        The function supports different scan modes: refreshing all files for a complete rescan,
        or refreshing only modified files for incremental updates. By default, only modified
        files are scanned for efficiency.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Specifies the unique identifier of the library to synchronize. Must be a valid GUID format.
        Accepts pipeline input by value and by property name for batch synchronization operations.
    .PARAMETER RefreshAllFiles
        When specified, forces a complete rescan of all files in the library regardless of
        modification status. This is useful for ensuring data integrity but may take longer.
        Default value is $false.
    .PARAMETER RefreshModifiedFiles
        When specified, scans only files that have been modified since the last scan.
        This is the default behavior and provides efficient incremental updates.
        Default value is $true.
    .EXAMPLE
        Sync-IMLibrary -Id 'bf973405-3f2a-48d2-a687-2ed4167164be'

        Starts a library synchronization scan for the specified library using default settings
        (incremental scan of modified files only).
    .EXAMPLE
        Sync-IMLibrary -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -RefreshAllFiles

        Performs a complete rescan of all files in the specified library.
    .EXAMPLE
        Get-IMLibrary | Sync-IMLibrary

        Synchronizes all libraries by processing library objects from the pipeline.
    .EXAMPLE
        $libraryIds = @('bf973405-3f2a-48d2-a687-2ed4167164be', '9c4e0006-3a2b-4967-94b6-7e8bb8490a12')
        $libraryIds | Sync-IMLibrary -RefreshAllFiles

        Performs complete rescans on multiple libraries specified by ID.
    .NOTES
        Library synchronization jobs run in the background. Use Get-IMJob to monitor
        the progress and status of initiated scan operations.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'FP')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id
    )

    process
    {
        $Id | ForEach-Object {
            $CurrentID = $PSItem
            InvokeImmichRestMethod -Method POST -RelativePath "/libraries/$CurrentID/scan" -ImmichSession:$Session
        }

    }
}
#endregion
