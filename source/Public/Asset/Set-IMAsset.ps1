function Set-IMAsset
{
    <#
    .DESCRIPTION
        Updates an Immich asset
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the asset to update
    .PARAMETER dateTimeOriginal
        Defines the assets taken date
    .PARAMETER isFavorite
        Defines if the asset should be set as favorite
    .PARAMETER latitude
        Set location latitude
    .PARAMETER longitude
        Set location longitude
    .PARAMETER description
        Defines a description
    .PARAMETER AddToAlbum
        Defines if the asset should be added to an album
    .PARAMETER RemoveFromAlbum
        Defines if the asset should be removed from an album
    .PARAMETER AddTag
        Defines if a tag should be added to the asset
    .PARAMETER RemoveTag
        Defines if a tag should be removed from the asset
    .PARAMETER AddToFace
        Defines if the asset should be assign to a face
    .PARAMETER AddToMemory
        Defines if the asset should be added to a memory
    .PARAMETER RemoveFromMemory
        Defines if the asset should be removed from a memory
    .EXAMPLE
        Set-IMAsset -id <assetid> -AddTag <tagid>

        Adds a tag to an asset
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
        $AddToFace,

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
                        InvokeImmichRestMethod -Method Put -RelativePath "/assets/$object" -ImmichSession:$Session -Body:$BodyParameters
                        if ($PSBoundParameters.ContainsKey('AddToAlbum'))
                        {
                            $null = InvokeImmichRestMethod -Method PUT -RelativePath "/albums/$AddToAlbum/assets" -ImmichSession:$Session -Body:@{ids = [string[]]$object }
                        }
                        if ($PSBoundParameters.ContainsKey('RemoveFromAlbum'))
                        {
                            $null = InvokeImmichRestMethod -Method DELETE -RelativePath "/albums/$RemoveFromAlbum/assets" -ImmichSession:$Session -Body:@{ids = [string[]]$object }
                        }
                        if ($PSBoundParameters.ContainsKey('AddTag'))
                        {
                            $null = InvokeImmichRestMethod -Method PUT -RelativePath "/tags/$AddTag/assets" -ImmichSession:$Session -Body:@{ids = [string[]]$object }
                        }
                        if ($PSBoundParameters.ContainsKey('RemoveTag'))
                        {
                            $null = InvokeImmichRestMethod -Method DELETE -RelativePath "/tags/$AddTag/assets" -ImmichSession:$Session -Body:@{ids = [string[]]$object }
                        }
                        if ($PSBoundParameters.ContainsKey('AddToFace'))
                        {
                            $null = InvokeImmichRestMethod -Method PUT -RelativePath "/faces/$AddToFace" -ImmichSession:$Session -Body:@{id = [string[]]$object }
                        }
                        if ($PSBoundParameters.ContainsKey('AddToMemory'))
                        {
                            $null = InvokeImmichRestMethod -Method PUT -RelativePath "/memories/$AddToMemory/assets" -ImmichSession:$Session -Body:@{ids = [string[]]$object }
                        }
                        if ($PSBoundParameters.ContainsKey('RemoveFromMemory'))
                        {
                            $null = InvokeImmichRestMethod -Method DELETE -RelativePath "/memories/$RemoveFromMemory/assets" -ImmichSession:$Session -Body:@{ids = [string[]]$object }
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
                    InvokeImmichRestMethod -Method Put -RelativePath '/assets' -ImmichSession:$Session -Body:$BodyParameters
                    if ($PSBoundParameters.ContainsKey('AddToAlbum'))
                    {
                        $null = InvokeImmichRestMethod -Method PUT -RelativePath "/albums/$AddToAlbum/assets" -ImmichSession:$Session -Body:@{ids = [string[]]($BodyParameters.ids) }
                    }
                    if ($PSBoundParameters.ContainsKey('RemoveFromAlbum'))
                    {
                        $null = InvokeImmichRestMethod -Method DELETE -RelativePath "/albums/$RemoveFromAlbum/assets" -ImmichSession:$Session -Body:@{ids = [string[]]($BodyParameters.ids) }
                    }
                    if ($PSBoundParameters.ContainsKey('AddTag'))
                    {
                        $null = InvokeImmichRestMethod -Method PUT -RelativePath "/tags/$AddTag/assets" -ImmichSession:$Session -Body:@{ids = [string[]]($BodyParameters.ids) }
                    }
                    if ($PSBoundParameters.ContainsKey('RemoveTag'))
                    {
                        $null = InvokeImmichRestMethod -Method DELETE -RelativePath "/tags/$RemoveTag/assets" -ImmichSession:$Session -Body:@{ids = [string[]]($BodyParameters.ids) }
                    }
                    if ($PSBoundParameters.ContainsKey('AddToFace'))
                    {
                        $null = InvokeImmichRestMethod -Method PUT -RelativePath "/faces/$AddToFace" -ImmichSession:$Session -Body:@{id = [string[]]($BodyParameters.ids) }
                    }
                    if ($PSBoundParameters.ContainsKey('AddToMemory'))
                    {
                        $null = InvokeImmichRestMethod -Method PUT -RelativePath "/memories/$AddToMemory/assets" -ImmichSession:$Session -Body:@{ids = [string[]]$object }
                    }
                    if ($PSBoundParameters.ContainsKey('RemoveFromMemory'))
                    {
                        $null = InvokeImmichRestMethod -Method DELETE -RelativePath "/memories/$RemoveFromMemory/assets" -ImmichSession:$Session -Body:@{ids = [string[]]$object }
                    }

                }
            }
        }
    }
}
#endregion
