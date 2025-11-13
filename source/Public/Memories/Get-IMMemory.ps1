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
        $id
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
            InvokeImmichRestMethod -Method Get -RelativePath '/memories' -ImmichSession:$Session
        }
    }
}
#endregion
