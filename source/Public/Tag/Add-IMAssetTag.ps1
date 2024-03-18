function Add-IMAssetTag
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
    .EXAMPLE
        Add-IMAssetTag

        Add Immich asset tag
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
            InvokeImmichRestMethod -Method PUT -RelativePath "/tag/$tagid/assets" -ImmichSession:$Session -Body:$BodyParameters
        }
    }
}
#endregion
