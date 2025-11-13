function Remove-IMMemory
{
    <#
    .SYNOPSIS
        Removes an Immich memory collection.
    .DESCRIPTION
        The Remove-IMMemory function permanently deletes a memory from Immich. Memories are
        curated collections of assets organized around specific dates or themes, and removing
        them eliminates the memory collection while leaving the underlying assets intact.

        This function supports pipeline input for batch operations and includes confirmation
        prompts to help prevent accidental deletions. The deletion only affects the memory
        organization structure and does not impact the individual assets contained within.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Specifies the unique identifier(s) of the memory to remove. Must be valid GUID format.
        Accepts pipeline input by value and by property name for batch deletion operations.
        This parameter has an alias 'libraryId' for compatibility purposes.
    .EXAMPLE
        Remove-IMMemory -Id 'bf973405-3f2a-48d2-a687-2ed4167164be'

        Removes the memory with the specified ID after confirmation prompt.
    .EXAMPLE
        Remove-IMMemory -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -Confirm:$false

        Removes the memory without prompting for confirmation.
    .EXAMPLE
        Get-IMMemory | Where-Object Type -eq 'on_this_day' | Remove-IMMemory

        Removes all 'on_this_day' type memories using pipeline processing.
    .EXAMPLE
        $oldMemories = Get-IMMemory | Where-Object { $_.memoryAt -lt (Get-Date).AddYears(-2) }
        $oldMemories | Remove-IMMemory -WhatIf

        Shows what would happen if memories older than 2 years were removed, without actually deleting them.
    .NOTES
        This function supports ShouldProcess for confirmation prompts. Use -WhatIf to preview
        changes and -Confirm to control confirmation behavior. Removing memories only affects
        the memory collections and does not delete the underlying assets.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('libraryId')]
        [string[]]
        $id
    )

    process
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'DELETE'))
            {
                InvokeImmichRestMethod -Method Delete -RelativePath "/memories/$CurrentID" -ImmichSession:$Session
            }
        }
    }
}
#endregion
