function Set-IMTag
{
    <#
    .DESCRIPTION
        Add Immich asset tag
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines an asset id to tag
    .PARAMETER tagId
        Defines a tag id to assign to assets
    .PARAMETER tagName
        Defines a tag name to assign to assets. Note that the Immich API does support filtering on tagName so all tags will be retreived and then filtered. This means that if there is a very large amount of tags this method might be slow.
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

    BEGIN
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

    PROCESS
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($id, 'Update tag'))
            {
                if ($PSBoundParameters.Keys -contains 'AddAssets') {
                    InvokeImmichRestMethod -Method PUT -RelativePath "/tags/$PSitem/assets" -ImmichSession:$Session -Body:@{ids = ($AddAssets -as [string[]])}
                }
                if ($PSBoundParameters.Keys -contains 'RemoveAssets') {
                    InvokeImmichRestMethod -Method DELETE -RelativePath "/tags/$PSitem/assets" -ImmichSession:$Session -Body:@{ids = ($RemoveAssets -as [string[]])}
                }
                if ($PSBoundParameters.Keys -contains 'Color') {
                    InvokeImmichRestMethod -Method PUT -RelativePath "/tags/$PSitem" -ImmichSession:$Session -Body:@{color = $Color}
                }
            }
        }
    }
}
#endregion
