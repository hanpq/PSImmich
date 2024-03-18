function Remove-IMAssetTag
{
    <#
    .DESCRIPTION
        Removes Immich asset tag
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines an asset id to remove tag from
    .PARAMETER tagId
        Defines a tag id to unassign from assets
    .PARAMETER tagName
        Defines a tag name to unassign from assets. Note that the Immich API does support filtering on tagName so all tags will be retreived and then filtered. This means that if there is a very large amount of tags this method might be slow.
    .EXAMPLE
        Remove-IMAssetTag

        Removes Immich asset tag
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'tagId')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'tagid')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $tagId,

        [Parameter(Mandatory, ParameterSetName = 'tagName')]
        [string]
        $tagName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('assetId')]
        [string[]]
        $id
    )

    BEGIN
    {
        $AssetIDs = [System.Collections.Generic.List[string]]::New()
        if ($PSCmdlet.ParameterSetName -eq 'tagName')
        {
            $TagObject = Get-IMTag | Where-Object { $_.name -eq $tagName }
            if ($TagObject)
            {
                $tagId = $TagObject.id
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
            $AssetIDs.Add($PSItem)
        }
    }

    END
    {
        if ($PSCmdlet.ShouldProcess(($AssetIDs -join ','), 'Add'))
        {
            $BodyParameters = @{
                assetIds = ($AssetIDs -as [string[]])
            }
            InvokeImmichRestMethod -Method DELETE -RelativePath "/tag/$tagid/assets" -ImmichSession:$Session -Body:$BodyParameters
        }
    }
}
#endregion
