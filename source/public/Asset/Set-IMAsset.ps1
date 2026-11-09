function Set-IMAsset
{
    <#
    .SYNOPSIS
        Updates Immich asset properties and associations
    .DESCRIPTION
        Updates various properties of Immich assets including metadata, location, favorites status, and manages
        associations with albums, tags, faces, and memories. Supports batch operations on multiple assets.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the asset(s) to update. Accepts pipeline input and multiple values.
    .PARAMETER DateTimeOriginal
        The original date and time when the asset was created/taken.
    .PARAMETER IsFavorite
        Specifies whether the asset should be marked as a favorite.
    .PARAMETER Latitude
        The latitude coordinate for the asset's location.
    .PARAMETER Longitude
        The longitude coordinate for the asset's location.
    .PARAMETER Description
        A description or caption for the asset.
    .PARAMETER AddToAlbum
        The UUID of an album to add the asset(s) to.
    .PARAMETER RemoveFromAlbum
        The UUID of an album to remove the asset(s) from.
    .PARAMETER AddTag
        The UUID of a tag to add to the asset(s).
    .PARAMETER RemoveTag
        The UUID of a tag to remove from the asset(s).
    .PARAMETER AddToFace
        The UUID of a face to associate the asset(s) with.
    .PARAMETER AddToMemory
        The UUID of a memory to add the asset(s) to.
    .PARAMETER RemoveFromMemory
        The UUID of a memory to remove the asset(s) from.
    .EXAMPLE
        Set-IMAsset -Id 'asset-uuid' -IsFavorite:$true

        Marks the specified asset as a favorite.
    .EXAMPLE
        Set-IMAsset -Id 'asset-uuid' -AddTag 'tag-uuid'

        Adds a tag to the specified asset.
    .EXAMPLE
        Set-IMAsset -Id 'asset-uuid' -Latitude 40.7128 -Longitude -74.0060 -Description 'New York City'

        Updates the location and description for the asset.
    .EXAMPLE
        @('asset1-uuid', 'asset2-uuid') | Set-IMAsset -AddToAlbum 'album-uuid'

        Adds multiple assets to an album via pipeline.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before making changes.
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'batch')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'batch')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'id')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('ids')]
        [string[]]
        $Id,

        [Parameter(ParameterSetName = 'batch')]
        [Parameter(ParameterSetName = 'id')]
        [ApiParameter('dateTimeOriginal')]
        [string]
        $DateTimeOriginal,

        [Parameter(ParameterSetName = 'batch')]
        [Parameter(ParameterSetName = 'id')]
        [ApiParameter('isFavorite')]
        [boolean]
        $IsFavorite,

        [Parameter(ParameterSetName = 'batch')]
        [Parameter(ParameterSetName = 'id')]
        [ApiParameter('latitude')]
        [Int32]
        $Latitude,

        [Parameter(ParameterSetName = 'batch')]
        [Parameter(ParameterSetName = 'id')]
        [ApiParameter('longitude')]
        [int32]
        $Longitude,

        [Parameter(ParameterSetName = 'id')]
        [ApiParameter('description')]
        [string]
        $Description,

        [Parameter()]
        [string]
        $AddToAlbum,

        [Parameter()]
        [string]
        $RemoveFromAlbum,

        [Parameter()]
        [string]
        $AddTag,

        [Parameter()]
        [string]
        $RemoveTag,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $AddToMemory,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $RemoveFromMemory

    )

    begin
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'batch'
            {
                $BodyParameters = @{
                    ids = @()
                }
                $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
            }
            'id'
            {
                $BodyParameters = @{}
                $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
            }
        }
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'batch'
            {
                $Id | ForEach-Object {
                    $BodyParameters.ids += $psitem
                }
            }
            'id'
            {
                foreach ($object in $Id)
                {
                    if ($PSCmdlet.ShouldProcess($object, 'PUT'))
                    {
                        Invoke-ImmichApiUpdateAsset -Id $object -Body $BodyParameters -ImmichSession $Session
                        if ($PSBoundParameters.ContainsKey('AddToAlbum'))
                        {
                            $null = Invoke-ImmichApiAddAssetsToAlbum -Id $AddToAlbum -Body @{ids = [string[]]$object } -ImmichSession $Session
                        }
                        if ($PSBoundParameters.ContainsKey('RemoveFromAlbum'))
                        {
                            $null = Invoke-ImmichApiRemoveAssetFromAlbum -Id $RemoveFromAlbum -Body @{ids = [string[]]$object } -ImmichSession $Session
                        }
                        if ($PSBoundParameters.ContainsKey('AddTag'))
                        {
                            $null = Invoke-ImmichApiTagAssets -Id $AddTag -Body @{ids = [string[]]$object } -ImmichSession $Session
                        }
                        if ($PSBoundParameters.ContainsKey('RemoveTag'))
                        {
                            $null = Invoke-ImmichApiUntagAssets -Id $RemoveTag -Body @{ids = [string[]]$object } -ImmichSession $Session
                        }
                        if ($PSBoundParameters.ContainsKey('AddToMemory'))
                        {
                            $null = Invoke-ImmichApiAddMemoryAssets -Id $AddToMemory -Body @{ids = [string[]]$object } -ImmichSession $Session
                        }
                        if ($PSBoundParameters.ContainsKey('RemoveFromMemory'))
                        {
                            $null = Invoke-ImmichApiRemoveMemoryAssets -Id $RemoveFromMemory -Body @{ids = [string[]]$object } -ImmichSession $Session
                        }
                    }
                }
            }
        }
    }

    end
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'batch'
            {
                if ($PSCmdlet.ShouldProcess(($BodyParameters.ids -join ','), 'PUT'))
                {
                    Invoke-ImmichApiUpdateAssets -Body $BodyParameters -ImmichSession $Session
                    if ($PSBoundParameters.ContainsKey('AddToAlbum'))
                    {
                        $null = Invoke-ImmichApiAddAssetsToAlbum -Id $AddToAlbum -Body @{ids = [string[]]($BodyParameters.ids) } -ImmichSession $Session
                    }
                    if ($PSBoundParameters.ContainsKey('RemoveFromAlbum'))
                    {
                        $null = Invoke-ImmichApiRemoveAssetFromAlbum -Id $RemoveFromAlbum -Body @{ids = [string[]]($BodyParameters.ids) } -ImmichSession $Session
                    }
                    if ($PSBoundParameters.ContainsKey('AddTag'))
                    {
                        $null = Invoke-ImmichApiTagAssets -Id $AddTag -Body @{ids = [string[]]($BodyParameters.ids) } -ImmichSession $Session
                    }
                    if ($PSBoundParameters.ContainsKey('RemoveTag'))
                    {
                        $null = Invoke-ImmichApiUntagAssets -Id $RemoveTag -Body @{ids = [string[]]($BodyParameters.ids) } -ImmichSession $Session
                    }
                    if ($PSBoundParameters.ContainsKey('AddToMemory'))
                    {
                        $null = Invoke-ImmichApiAddMemoryAssets -Id $AddToMemory -Body @{ids = [string[]]($BodyParameters.ids) } -ImmichSession $Session
                    }
                    if ($PSBoundParameters.ContainsKey('RemoveFromMemory'))
                    {
                        $null = Invoke-ImmichApiRemoveMemoryAssets -Id $RemoveFromMemory -Body @{ids = [string[]]($BodyParameters.ids) } -ImmichSession $Session
                    }

                }
            }
        }
    }
}
#endregion
