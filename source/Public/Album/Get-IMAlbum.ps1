﻿function Get-IMAlbum
{
    <#
    .DESCRIPTION
        Retreives Immich asset
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines the album to get
    .PARAMETER assetId
        Only returns albums that contain the asset
    .PARAMETER shared
        Defines weather to return shared albums or not.
    .PARAMETER withoutAssets
        Defines weather to return assets as part of the object or not
    .EXAMPLE
        Get-IMAlbum -albumid <albumid>

        Retreives Immich album
    #>

    [CmdletBinding(DefaultParameterSetName = 'list-shared')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('id')]
        [string]
        $albumId,

        [Parameter(Mandatory, ParameterSetName = 'list-asset')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $assetId,

        [Parameter(ParameterSetName = 'id')]
        [switch]
        $withoutAssets,

        [Parameter(ParameterSetName = 'list-shared')]
        [boolean]
        $shared
    )

    BEGIN
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list-shared'
            {
                $QueryParameters = @{}
                $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'shared')
            }
            'list-asset'
            {
                $QueryParameters = @{}
                $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'assetId')
            }
            'id'
            {
                $QueryParameters = @{}
                $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'withoutAssets')
            }
        }
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list-shared'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/album' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'id'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/album/$albumId" -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'list-asset'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/album' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
        }
    }

}
#endregion
