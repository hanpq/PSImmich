function Set-IMTag
{
    <#
    .SYNOPSIS
        Assigns tags to assets.
    .DESCRIPTION
        Associates tags with assets for organization and categorization.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Asset ID(s) to tag.
    .PARAMETER TagId
        Tag ID to assign to assets.
    .PARAMETER TagName
        Tag name to assign. Slower than TagId for large tag collections.
    .PARAMETER AddAssets
        Defines the assets to tag
    .PARAMETER RemoveAssets
        Defines the assets to untag
    .PARAMETER Color
        Defines the tag color, acceppts a HEX string ie, #000000
    .EXAMPLE
        Set-IMTag -AddAssets <assetid>

        Add tag to asset
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'tagId')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'tagid', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id,

        [Parameter(Mandatory, ParameterSetName = 'tagName')]
        [string]
        $tagName,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $AddAssets,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $RemoveAssets,

        [Parameter()]
        [string]
        $Color
    )

    begin
    {
        if ($PSCmdlet.ParameterSetName -eq 'tagName')
        {
            $TagObject = Get-IMTag | Where-Object { $_.name -eq $tagName }
            if ($TagObject)
            {
                $id = $TagObject.id
            }
            else
            {
                throw "Unable to find tag with name $($tagName)"
            }
        }
    }

    process
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($id, 'Update tag'))
            {
                if ($PSBoundParameters.Keys -contains 'AddAssets')
                {
                    InvokeImmichRestMethod -Method PUT -RelativePath "/tags/$PSitem/assets" -ImmichSession:$Session -Body:@{ids = ($AddAssets -as [string[]]) }
                }
                if ($PSBoundParameters.Keys -contains 'RemoveAssets')
                {
                    InvokeImmichRestMethod -Method DELETE -RelativePath "/tags/$PSitem/assets" -ImmichSession:$Session -Body:@{ids = ($RemoveAssets -as [string[]]) }
                }
                if ($PSBoundParameters.Keys -contains 'Color')
                {
                    InvokeImmichRestMethod -Method PUT -RelativePath "/tags/$PSitem" -ImmichSession:$Session -Body:@{color = $Color }
                }
            }
        }
    }
}
#endregion
