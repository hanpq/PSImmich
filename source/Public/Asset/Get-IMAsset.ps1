function Get-IMAsset
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
    .PARAMETER deviceId
        Defines a device id
    .PARAMETER personId
        Defines a personId to retreive assets for
    .PARAMETER tagId
        Defines a tagid to retreive assets for
    .PARAMETER Random
        Defines that random assets should be retreived. Unless -count is also specified one random asset is returned.
    .PARAMETER Count
        Defines how many random assets should be returned. Required -Random
    .EXAMPLE
        Get-IMAsset -isFavorite:$true

        Retreives all favorites
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'random')]
        [switch]
        $Random,

        [Parameter(ParameterSetName = 'random')]
        [int]
        $Count,

        [Parameter(Mandatory, ParameterSetName = 'deviceid')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $deviceID,

        [Parameter(Mandatory, ParameterSetName = 'personid')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $personId,

        [Parameter(Mandatory, ParameterSetName = 'tagid')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $tagId,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $id
    )

    BEGIN
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'id'
            {
                $QueryParameters = @{}
                $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'isFavorite', 'isArchived', 'skip', 'take', 'updatedAfter', 'updatedBefore', 'userId', 'key')
            }
            'random'
            {
                $QueryParameters = @{}
                $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'count' -NameMapping @{Count = 'count' })
            }
        }
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'id'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/assets/$id" -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'deviceid'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/assets/device/$deviceid" -ImmichSession:$Session | Get-IMAsset
            }
            'personId'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/people/$personid/assets" -ImmichSession:$Session | Get-IMAsset
            }
            'tagid'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/tags/$tagid/assets" -ImmichSession:$Session | Get-IMAsset
            }
            'random'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/assets/random' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'list'
            {
                Find-IMAsset
                Write-Warning -Message 'Previous versions of Immich allowed enumeration of all assets using the Assets endpoint. This is deprecated and Find- should now be used. To enumerate all assets you can call Find-IMAsset.'
            }
        }
    }
}
#endregion
