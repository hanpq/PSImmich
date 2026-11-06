function Get-IMMemory
{
    <#
    .SYNOPSIS
        Retrieves Immich memories and memory collections.
    .DESCRIPTION
        The Get-IMMemory function retrieves memories from Immich, which are curated collections
        of assets organized around specific dates, events, or themes. Memories help users
        rediscover and enjoy their photo collections through automated or manual curation.

        When called without parameters, the function returns all available memories.
        When provided with specific memory IDs, it returns detailed information about
        those particular memories, including associated assets and metadata.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Specifies the unique identifier(s) of specific memories to retrieve. Must be valid GUID format.
        Accepts pipeline input by value and by property name for batch retrieval operations.
        When omitted, all available memories are returned.
    .PARAMETER Order
        Specifies the sort order for returned memories when retrieving all memories.
        Valid values are 'asc' (ascending), 'desc' (descending), or 'random' (random order).
        Only applies when retrieving all memories (list parameter set).
    .PARAMETER For
        Specifies a specific date to retrieve memories for. Memories associated with or created
        around this date will be returned. Only applies when retrieving all memories.
    .PARAMETER NumberOfMemories
        Specifies the maximum number of memories to return when retrieving all memories.
        This parameter limits the result set size for performance and pagination purposes.
        Alias: Size. Only applies when retrieving all memories (list parameter set).
    .PARAMETER IsSaved
        When specified, filters to return only memories that have been marked as saved.
        Only applies when retrieving all memories (list parameter set).
    .PARAMETER IsTrashed
        When specified, filters to return only memories that have been moved to trash.
        Only applies when retrieving all memories (list parameter set).
    .PARAMETER Type
        Specifies the type of memories to retrieve. Currently supports 'on_this_day' type
        which returns memories from the same date in previous years. Only applies when
        retrieving all memories (list parameter set).
    .PARAMETER Statistics
        When specified, retrieves memory statistics instead of memory objects. Returns
        statistical information about memories such as counts, distributions, and summaries.
        This creates a separate parameter set that supports Order and NumberOfMemories parameters.
    .EXAMPLE
        Get-IMMemory

        Retrieves all available memories from the Immich instance.
    .EXAMPLE
        Get-IMMemory -Id 'bf973405-3f2a-48d2-a687-2ed4167164be'

        Retrieves detailed information about the memory with the specified ID.
    .EXAMPLE
        $memoryIds = @('bf973405-3f2a-48d2-a687-2ed4167164be', '9c4e0006-3a2b-4967-94b6-7e8bb8490a12')
        $memoryIds | Get-IMMemory

        Retrieves multiple specific memories using pipeline input.
    .EXAMPLE
        Get-IMMemory | Where-Object { $_.assets.Count -gt 10 }

        Gets all memories and filters to show only those containing more than 10 assets.
    .EXAMPLE
        Get-IMMemory -Order desc -NumberOfMemories 5

        Retrieves the 5 most recent memories in descending order.
    .EXAMPLE
        Get-IMMemory -Type on_this_day -For (Get-Date '2023-12-25')

        Retrieves "on this day" memories for Christmas 2023, showing memories from December 25th in previous years.
    .EXAMPLE
        Get-IMMemory -IsSaved -Order asc

        Retrieves all saved memories in ascending (oldest first) order.
    .EXAMPLE
        Get-IMMemory -Statistics

        Retrieves memory statistics and summary information.
    .EXAMPLE
        Get-IMMemory -Statistics -Order desc -NumberOfMemories 10

        Retrieves memory statistics with descending order, limited to 10 results.
    .NOTES
        Memories represent curated collections that help users rediscover their photos.
        The 'list' parameter set returns all memories, while the 'id' parameter set returns specific memories.
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id,

        [Parameter(ParameterSetName = 'list')]
        [Parameter(ParameterSetName = 'statistics')]
        [ApiParameter('order')]
        [ValidateSet('asc', 'desc', 'random')]
        [string]
        $Order,

        [Parameter(ParameterSetName = 'list')]
        [Parameter(ParameterSetName = 'statistics')]
        [ApiParameter('for')]
        [datetime]
        $For,

        [Parameter(ParameterSetName = 'list')]
        [Parameter(ParameterSetName = 'statistics')]
        [ApiParameter('size')]
        [Alias('Size')]
        [int]
        $NumberOfMemories,

        [Parameter(ParameterSetName = 'list')]
        [Parameter(ParameterSetName = 'statistics')]
        [ApiParameter('isSaved')]
        [switch]
        $IsSaved,

        [Parameter(ParameterSetName = 'list')]
        [Parameter(ParameterSetName = 'statistics')]
        [ApiParameter('isTrashed')]
        [switch]
        $IsTrashed,

        [Parameter(ParameterSetName = 'list')]
        [Parameter(ParameterSetName = 'statistics')]
        [ApiParameter('type')]
        [ValidateSet('on_this_day')]
        [string]
        $Type,

        [Parameter(Mandatory, ParameterSetName = 'statistics')]
        [switch]
        $Statistics
    )

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'id')
        {
            $id | ForEach-Object {
                InvokeImmichRestMethod -Method Get -RelativePath "/memories/$PSItem" -ImmichSession:$Session
            }
        }
    }

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            $QueryParameters = @{}
            $QueryParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
            InvokeImmichRestMethod -Method Get -RelativePath '/memories' -ImmichSession:$Session -QueryParameters $QueryParameters
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'statistics')
        {
            $QueryParameters = @{}
            $QueryParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
            InvokeImmichRestMethod -Method Get -RelativePath '/memories/statistics' -ImmichSession:$Session -QueryParameters $QueryParameters
        }
    }
}
#endregion
