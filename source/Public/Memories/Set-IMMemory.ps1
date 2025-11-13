function Set-IMMemory
{
    <#
    .SYNOPSIS
        Updates an existing Immich memory configuration.
    .DESCRIPTION
        The Set-IMMemory function modifies the properties of an existing memory in Immich.
        You can update the memory's anchor date, tracking information, and saved status.
        This function supports pipeline input for batch operations and includes confirmation
        prompts for safety when making changes to memory configurations.

        Memories are curated collections that help users rediscover their photos, and
        updating their properties can improve the user experience and memory organization.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Specifies the unique identifier of the memory to update. Must be a valid GUID format.
        Accepts pipeline input by value and by property name for batch update operations.
    .PARAMETER IsSaved
        Controls whether the memory is marked as saved by the user. Set to $true to save
        the memory for future reference, or $false to unsave it. Saved memories may receive
        different treatment in the user interface.
    .PARAMETER MemoryAt
        Updates the date and time when the memory is anchored. This represents the focal
        point of the memory and affects how it's organized and presented to users.
        Must be provided in a valid DateTime format.
    .PARAMETER SeenAt
        Updates the timestamp indicating when the memory was last viewed or acknowledged
        by the user. This helps track engagement and can influence memory presentation logic.
    .EXAMPLE
        Set-IMMemory -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -IsSaved $true

        Marks the specified memory as saved for future reference.
    .EXAMPLE
        Set-IMMemory -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -MemoryAt "2024-07-04 12:00:00"

        Updates the memory's anchor date to July 4th, 2024 at noon.
    .EXAMPLE
        Get-IMMemory | Where-Object IsSaved -eq $false | Set-IMMemory -IsSaved $true

        Marks all unsaved memories as saved using pipeline processing.
    .EXAMPLE
        Set-IMMemory -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -SeenAt (Get-Date)

        Updates the memory's last seen timestamp to the current date and time.
    .NOTES
        This function supports ShouldProcess for confirmation prompts when making changes.
        Use -WhatIf to preview changes before applying them to memory configurations.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id,

        [Parameter()]
        [ApiParameter('isSaved')]
        [boolean]
        $IsSaved,

        [Parameter()]
        [ApiParameter('memoryAt')]
        [datetime]
        $MemoryAt,

        [Parameter()]
        [ApiParameter('seenAt')]
        [datetime]
        $SeenAt

    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        $Id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Update'))
            {
                InvokeImmichRestMethod -Method PUT -RelativePath "/memories/$PSItem" -ImmichSession:$Session -Body:$BodyParameters
            }
        }
    }
}
#endregion
