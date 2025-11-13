function Get-IMAsset
{
    <#
    .DESCRIPTION
        Retrieves Immich assets using different parameter sets for various use cases
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.

        -Session $Session
    .PARAMETER Id
        Defines a specific asset ID to be retrieved. Used with the 'id' parameter set.
    .PARAMETER Key
        Defines an optional key parameter for asset retrieval. Used with the 'id' parameter set.
    .PARAMETER Slug
        Defines an optional slug parameter for asset retrieval. Used with the 'id' parameter set.
    .PARAMETER DeviceID
        Defines a device ID to retrieve assets for a specific device. Uses the 'deviceid' parameter set.
    .PARAMETER PersonId
        Defines a person ID to retrieve assets associated with a specific person. Uses the 'personid' parameter set.
    .PARAMETER TagId
        Defines a tag ID to retrieve assets with a specific tag. Uses the 'tagid' parameter set.
    .PARAMETER Random
        Specifies that random assets should be retrieved. Uses the 'random' parameter set.
    .PARAMETER Count
        Defines how many random assets should be returned when using -Random. Default is 1, maximum is 1000.
    .EXAMPLE
        Get-IMAsset -Id '550e8400-e29b-41d4-a716-446655440000'

        Retrieves a specific asset by its ID
    .EXAMPLE
        Get-IMAsset -Random -Count 5

        Retrieves 5 random assets
    .EXAMPLE
        Get-IMAsset -PersonId '550e8400-e29b-41d4-a716-446655440001'

        Retrieves all assets associated with a specific person
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
