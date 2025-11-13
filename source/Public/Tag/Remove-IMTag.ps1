function Remove-IMTag
{
    <#
    .SYNOPSIS
        Removes an asset tag.
    .DESCRIPTION
        Deletes a tag and removes it from all associated assets.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Tag ID to remove.
    .EXAMPLE
        Remove-IMTag -Id 'tag-id'

        Removes tag and all associations.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id
    )

    process
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'Remove'))
            {
                InvokeImmichRestMethod -Method DELETE -RelativePath "/tags/$CurrentID" -ImmichSession:$Session
            }
        }
    }
}
#endregion
