function Get-IMAsset
{
    <#
    .SYNOPSIS
        Retrieves Immich assets
    .DESCRIPTION
        Retrieves assets from the Immich server using various criteria. Supports retrieving specific assets by ID,
        random assets, assets by device, person, or tag associations, and general asset searches.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of a specific asset to retrieve. Accepts pipeline input.
    .PARAMETER Key
        An optional API key for shared link access when retrieving assets.
    .PARAMETER Slug
        An optional slug for shared link access when retrieving assets.
    .PARAMETER DeviceID
        The device ID to retrieve assets from a specific device.
    .PARAMETER PersonId
        The UUID of a person to retrieve associated assets.
    .PARAMETER TagId
        The UUID of a tag to retrieve assets with that tag.
    .PARAMETER Random
        Specifies that random assets should be retrieved instead of a specific asset.
    .PARAMETER Count
        The number of random assets to return when using -Random. Default is 1, maximum is 1000.
    .EXAMPLE
        Get-IMAsset

        Retrieves all assets using the default search.
    .EXAMPLE
        Get-IMAsset -Id '550e8400-e29b-41d4-a716-446655440000'

        Retrieves a specific asset by its UUID.
    .EXAMPLE
        Get-IMAsset -Random -Count 5

        Retrieves 5 random assets from the library.
    .EXAMPLE
        Get-IMAsset -PersonId '550e8400-e29b-41d4-a716-446655440001'

        Retrieves all assets associated with a specific person.
    .EXAMPLE
        Get-IMAsset -TagId 'tag-uuid'

        Retrieves all assets tagged with the specified tag.
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
        [ValidateRange(1, 1000)]
        [int]
        $Count = 1,

        [Parameter(Mandatory, ParameterSetName = 'deviceid')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $DeviceID,

        [Parameter(Mandatory, ParameterSetName = 'personid')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $PersonId,

        [Parameter(Mandatory, ParameterSetName = 'tagid')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $TagId,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter(ParameterSetName = 'id')]
        [ApiParameter('key')]
        [string]
        $Key,

        [Parameter(ParameterSetName = 'id')]
        [ApiParameter('slug')]
        [string]
        $Slug
    )

    begin
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'id'
            {
                $QueryParameters = @{}
                $QueryParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
            }
        }
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'id'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/assets/$Id" -ImmichSession:$Session -QueryParameters $QueryParameters | AddCustomType IMAsset
            }
            'deviceid'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/assets/device/$DeviceID" -ImmichSession:$Session | Get-IMAsset
            }
            'personId'
            {
                Find-IMAsset -personIds $PersonId -Session:$Session
            }
            'tagid'
            {
                $Body = @{
                    tagIds = @($TagId)
                }

                $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/metadata' -ImmichSession:$Session -Body $Body | Select-Object -ExpandProperty assets
                $Result | Select-Object -ExpandProperty items | AddCustomType IMAsset

                while ($Result.NextPage)
                {
                    $Body.page = $Result.NextPage
                    $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/metadata' -ImmichSession:$Session -Body $Body | Select-Object -ExpandProperty assets
                    $Result | Select-Object -ExpandProperty items | AddCustomType IMAsset
                }
            }
            'random'
            {
                # Requires body, but we wont provide any parameters in this case. TBD
                $Body = @{
                    size = $Count
                }
                InvokeImmichRestMethod -Method POST -RelativePath '/search/random' -ImmichSession:$Session -Body:$Body | AddCustomType IMAsset
            }
            'list'
            {
                Find-IMAsset
            }
        }
    }
}
#endregion
