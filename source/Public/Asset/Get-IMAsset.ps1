﻿function Get-IMAsset
{
    <#
    .DESCRIPTION
        Retreives Immich asset
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific asset id to be retreived
    .PARAMETER isFavorite
        Defines if faviorites should be returned or not. Do not specify if either should be returned.
    .PARAMETER isArchived
        Defines if archvied assets should be returned or not. Do not specify if either should be returned.
    .PARAMETER skip
        Defines skip
    .PARAMETER take
        Defines take
    .PARAMETER updatedAfter
        Deinfes updatedAfter
    .PARAMETER updatedBefore
        Defines updatedBefore
    .PARAMETER userId
        Defines userId
    .PARAMETER deviceID
        Defines a device id
    .EXAMPLE
        Get-IMAsset

        Retreives Immich asset
    .NOTES
        Covers api getAllAssets,getAllUserAssetsByDeviceId,getAssetInfo
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'deviceid')]
        [string]
        $deviceID,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $id,

        [Parameter(ParameterSetName = 'list')]
        [boolean]
        $isFavorite,

        [Parameter(ParameterSetName = 'list')]
        [boolean]
        $isArchived,

        [Parameter(ParameterSetName = 'list')]
        [int]
        $skip,

        [Parameter(ParameterSetName = 'list')]
        [int]
        $take,

        [Parameter(ParameterSetName = 'list')]
        [datetime]
        $updatedAfter,

        [Parameter(ParameterSetName = 'list')]
        [datetime]
        $updatedBefore,

        [Parameter(ParameterSetName = 'list')]
        [string]
        $userId
    )

    BEGIN
    {
        if (@('list', 'id') -contains $PSCmdlet.ParameterSetName)
        {
            $QueryParameters = @{}
            $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'isFavorite', 'isArchived', 'skip', 'take', 'updatedAfter', 'updatedBefore', 'userId', 'key')
        }
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/asset' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'id'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/asset/$id" -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'deviceid'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/asset/device/$deviceid" -ImmichSession:$Session | Get-IMAsset
            }
        }
    }

}
#endregion