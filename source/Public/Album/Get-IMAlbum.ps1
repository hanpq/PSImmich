function Get-IMAlbum
{
    <#
    .DESCRIPTION
        Retreives Immich asset
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER AlbumId
        Defines the album to get
    .PARAMETER AssetId
        Only returns albums that contain the asset
    .PARAMETER ExcludeShared
        Defines weather to return shared albums or not.
    .PARAMETER IncludeAssets
        Defines weather to return assets as part of the object or not
    .PARAMETER Name
        Get album by name
    .EXAMPLE
        Get-IMAlbum -albumid <albumid>

        Retreives Immich album
    #>

    [CmdletBinding(DefaultParameterSetName = 'list-shared')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Position = 1, Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('Id')]
        [string]
        $AlbumId,

        [Parameter(Mandatory, ParameterSetName = 'list-asset')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $AssetId,

        [Parameter(ParameterSetName = 'id')]
        [switch]
        $IncludeAssets,

        [Parameter(ParameterSetName = 'list-shared')]
        [Parameter(ParameterSetName = 'search-albumname')]
        [switch]
        $ExcludeShared,

        [Parameter(Position = 1, Mandatory, ParameterSetName = 'search-albumname')]
        [string]
        $Name

    )

    BEGIN
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list-shared'
            {
                $QueryParameters = @{}
                $QueryParameters.shared = (-not $ExcludeShared)
            }
            'search-albumname'
            {
                $QueryParameters = @{}
                $QueryParameters.shared = (-not $ExcludeShared)
            }
            'list-asset'
            {
                $QueryParameters = @{}
                $QueryParameters.assetId = $AssetId
            }
            'id'
            {
                $QueryParameters = @{}
                $QueryParameters.withoutAssets = (-not $IncludeAssets)
            }
        }
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'search-albumname'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/albums' -ImmichSession:$Session -QueryParameters $QueryParameters | Where-Object { $_.albumname -like "*$Name*" }
            }
            'list-shared'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/albums' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'id'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/albums/$AlbumId" -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'list-asset'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/albums' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
        }
    }

}
#endregion
