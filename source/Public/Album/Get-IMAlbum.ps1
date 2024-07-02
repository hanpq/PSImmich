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
    .PARAMETER Shared
        Defines weather to return shared albums or not.
    .PARAMETER IncludeAssets
        Defines weather to return assets as part of the object or not
    .PARAMETER Name
        Specify an exact name of an album
    .PARAMETER SearchString
        Specify a string to search for in album names, accepts wildcard
    .EXAMPLE
        Get-IMAlbum -albumid <albumid>

        Retreives Immich album
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('Id')]
        [string]
        $AlbumId,

        [Parameter(ParameterSetName = 'list')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $AssetId,

        [Parameter(ParameterSetName = 'id')]
        [Parameter(ParameterSetName = 'list')]
        [switch]
        $IncludeAssets,

        [Parameter(ParameterSetName = 'list')]
        [boolean]
        $Shared,

        [Parameter(ParameterSetName = 'list')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'list')]
        [string]
        $SearchString
    )

    BEGIN
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                $QueryParameters = @{}
                $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'Shared' -NameMapping @{'Shared' = 'shared' })
                $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'AssetId' -NameMapping @{'AssetId' = 'assetId' })
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
            'list'
            {
                $Result = InvokeImmichRestMethod -Method Get -RelativePath '/albums' -ImmichSession:$Session -QueryParameters $QueryParameters
                if ($Name)
                {
                    $Result = $Result | Where-Object { $_.AlbumName -eq $Name }
                }
                if ($SearchString)
                {
                    $Result = $Result | Where-Object { $_.Albumname -like $SearchString }
                }
                if (-not $IncludeAssets)
                {
                    $Result | AddCustomType IMAlbum
                }
                else
                {
                    $Result | ForEach-Object {
                        Get-IMAlbum -Id $PSItem.Id -IncludeAssets
                    } | AddCustomType IMAlbum
                }

            }
            'id'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/albums/$albumId" -ImmichSession:$Session -QueryParameters $QueryParameters | AddCustomType IMAlbum
            }
        }
    }

}
#endregion
