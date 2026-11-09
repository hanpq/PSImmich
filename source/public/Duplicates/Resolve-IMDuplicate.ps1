function Resolve-IMDuplicate
{
    <#
    .SYNOPSIS
        Resolves duplicate asset groups in Immich
    .DESCRIPTION
        Resolves one or more duplicate groups by specifying which assets to keep and which to move to the trash.
        Immich synchronizes metadata across the kept assets and trashes the others. Use Get-IMDuplicate to find the
        duplicate groups and their suggested assets to keep.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER DuplicateId
        The UUID of the duplicate group to resolve. Accepts pipeline input by property name, so Get-IMDuplicate can be piped in.
    .PARAMETER KeepAssetId
        The UUID(s) of the assets in the group to keep.
    .PARAMETER TrashAssetId
        The UUID(s) of the assets in the group to move to the trash.
    .EXAMPLE
        Get-IMDuplicate | ForEach-Object {
            $Group = $PSItem
            $Trash = $Group.Assets.Id | Where-Object { $PSItem -notin $Group.SuggestedKeepAssetIds }
            Resolve-IMDuplicate -DuplicateId $Group.DuplicateId -KeepAssetId $Group.SuggestedKeepAssetIds -TrashAssetId $Trash
        }

        Resolves each duplicate group by keeping the suggested assets and trashing the rest.
    .EXAMPLE
        Resolve-IMDuplicate -DuplicateId '5b0bbb8d-3a3e-4f46-a1ab-0e7a2a7f3c11' -KeepAssetId 'a1f0c6f2-1d43-4c1b-9d7e-2b0a6c3f8e10' -TrashAssetId 'b2e1d7a3-2e54-4d2c-8e8f-3c1b7d4f9f21' -WhatIf

        Shows what would be resolved without changing anything.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before trashing assets. Trashed assets
        can be restored from the Immich trash.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $DuplicateId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $KeepAssetId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $TrashAssetId
    )

    begin
    {
        $Groups = [System.Collections.Generic.List[hashtable]]::new()
    }

    process
    {
        $Groups.Add(@{
                duplicateId   = $DuplicateId
                keepAssetIds  = @($KeepAssetId)
                trashAssetIds = @($TrashAssetId)
            })
    }

    end
    {
        if ($PSCmdlet.ShouldProcess(($Groups.duplicateId -join ','), 'RESOLVE'))
        {
            $Body = @{
                groups = @($Groups)
            }
            Invoke-ImmichApiResolveDuplicates -Body $Body -ImmichSession $Session | Out-Null
        }
    }

}
#endregion
