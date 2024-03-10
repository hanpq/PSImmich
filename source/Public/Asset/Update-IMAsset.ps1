function Update-IMAsset
{
    <#
    .DESCRIPTION
        Updates an Immich asset
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER ids
        asd
    .PARAMETER dateTimeOriginal
    asd
    .PARAMETER isArchived
    asd
    .PARAMETER isFavorite
    asd
    .PARAMETER latitude
    asd
    .PARAMETER longitude
    asd
    .PARAMETER removeParent
    asd
    .PARAMETER stackParentId
    asd
    .PARAMETER description
    asd
    .EXAMPLE
        Update-IMAsset

        Update an Immich asset
    .NOTES
        Covers updateAssets, updateAsset
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'batch')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'batch')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'id')]
        [string[]]
        [Alias('id')]
        $ids,

        [Parameter(ParameterSetName = 'batch')]
        [Parameter(ParameterSetName = 'id')]
        [string]
        $dateTimeOriginal,

        [Parameter(ParameterSetName = 'batch')]
        [Parameter(ParameterSetName = 'id')]
        [boolean]
        $isArchived,

        [Parameter(ParameterSetName = 'batch')]
        [Parameter(ParameterSetName = 'id')]
        [boolean]
        $isFavorite,

        [Parameter(ParameterSetName = 'batch')]
        [Parameter(ParameterSetName = 'id')]
        [Int32]
        $latitude,

        [Parameter(ParameterSetName = 'batch')]
        [Parameter(ParameterSetName = 'id')]
        [int32]
        $longitude,

        [Parameter(ParameterSetName = 'batch')]
        [switch]
        $removeParent,

        [Parameter(ParameterSetName = 'batch')]
        [string]
        $stackParentId,

        [Parameter(ParameterSetName = 'id')]
        [string]
        $description
    )

    BEGIN
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'batch'
            {
                $BodyParameters = @{
                    ids = @()
                }
                $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'dateTimeOriginal', 'isFavorite', 'isArchived', 'latitude', 'longitude', 'removeParent', 'stackParentId')
            }
            'id'
            {
                $BodyParameters = @{}
                $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'dateTimeOriginal', 'isFavorite', 'isArchived', 'latitude', 'longitude', 'description')
            }
        }
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'batch'
            {
                $ids | ForEach-Object {
                    $BodyParameters.ids += $psitem
                }
            }
            'id'
            {
                foreach ($id in $ids)
                {
                    if ($PSCmdlet.ShouldProcess(($BodyParameters.ids -join ','), 'PUT'))
                    {
                        InvokeImmichRestMethod -Method Put -RelativePath "/asset/$id" -ImmichSession:$Session -Body:$BodyParameters
                    }
                }
            }
        }
    }

    END
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'batch'
            {
                if ($PSCmdlet.ShouldProcess(($BodyParameters.ids -join ','), 'PUT'))
                {
                    InvokeImmichRestMethod -Method Put -RelativePath '/asset' -ImmichSession:$Session -Body:$BodyParameters
                }
            }
        }
    }

}
#endregion
