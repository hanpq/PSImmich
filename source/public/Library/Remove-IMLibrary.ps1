function Remove-IMLibrary
{
    <#
    .SYNOPSIS
        Removes an Immich library and all associated assets.
    .DESCRIPTION
        The Remove-IMLibrary function permanently deletes an Immich library along with all
        its associated assets, metadata, and configuration settings. This is a destructive
        operation that cannot be undone, so it should be used with caution.

        The function supports pipeline input for batch operations and includes confirmation
        prompts to help prevent accidental deletions. When a library is removed, all assets
        within that library are also deleted from the Immich database, though the original
        files on the file system remain unchanged.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Specifies the unique identifier(s) of the library to remove. Must be valid GUID format.
        Accepts pipeline input by value and by property name for batch deletion operations.
        This parameter has an alias 'libraryId' for compatibility.
    .EXAMPLE
        Remove-IMLibrary -Id 'bf973405-3f2a-48d2-a687-2ed4167164be'

        Removes the library with the specified ID after confirmation prompt.
    .EXAMPLE
        Remove-IMLibrary -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -Confirm:$false

        Removes the library without prompting for confirmation (use with extreme caution).
    .EXAMPLE
        Get-IMLibrary | Where-Object Name -like '*test*' | Remove-IMLibrary

        Removes all libraries with 'test' in their name using pipeline processing.
    .EXAMPLE
        $librariesToRemove = @('bf973405-3f2a-48d2-a687-2ed4167164be', '9c4e0006-3a2b-4967-94b6-7e8bb8490a12')
        $librariesToRemove | Remove-IMLibrary -WhatIf

        Shows what would happen if the specified libraries were removed, without actually deleting them.
    .NOTES
        This function supports ShouldProcess for confirmation prompts. Use -WhatIf to preview
        changes and -Confirm to control confirmation behavior. Library removal is permanent
        and affects all assets within the library - ensure you have backups before proceeding.
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
        # We loop through IDs because ids can be provided as an array to the parameter in which case the process block only gets called once.
        $id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'DELETE'))
            {
                InvokeImmichRestMethod -Method Delete -RelativePath "/libraries/$CurrentID" -ImmichSession:$Session
            }
        }
    }
}
#endregion
