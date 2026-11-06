function Get-IMAlbum
{
    <#
    .SYNOPSIS
        Retrieves Immich albums
    .DESCRIPTION
        Retrieves one or more albums from the Immich server. Can retrieve all albums, specific albums by ID,
        albums containing specific assets, or filter albums by name or shared status.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER AlbumId
        The UUID of a specific album to retrieve. Accepts pipeline input.
    .PARAMETER AssetId
        Only returns albums that contain the specified asset UUID.
    .PARAMETER Shared
        Specifies whether to return shared albums. If not specified, returns both shared and non-shared albums.
    .PARAMETER IncludeAssets
        Specifies whether to include assets as part of the returned album objects. By default, assets are not included for performance.
    .PARAMETER Name
        Specifies the exact name of an album to retrieve.
    .PARAMETER SearchString
        Specifies a string to search for in album names. Supports wildcards for pattern matching.
    .EXAMPLE
        Get-IMAlbum

        Retrieves all albums for the current user.
    .EXAMPLE
        Get-IMAlbum -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retrieves a specific album by its ID.
    .EXAMPLE
        Get-IMAlbum -Name 'Family Vacation'

        Retrieves the album with the exact name 'Family Vacation'.
    .EXAMPLE
        Get-IMAlbum -SearchString 'vacation*' -IncludeAssets

        Retrieves all albums with names starting with 'vacation' and includes their assets.
    .EXAMPLE
        Get-IMAlbum -Shared:$true

        Retrieves only albums that are shared with other users.
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
        [ApiParameter('assetId')]
        [string]
        $AssetId,

        [Parameter(ParameterSetName = 'id')]
        [Parameter(ParameterSetName = 'list')]
        [switch]
        $IncludeAssets,

        [Parameter(ParameterSetName = 'list')]
        [ApiParameter('shared')]
        [boolean]
        $Shared,

        [Parameter(ParameterSetName = 'list')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'list')]
        [string]
        $SearchString
    )

    begin
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                $QueryParameters = @{}
                $QueryParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
            }
            'id'
            {
                $QueryParameters = @{}
                $QueryParameters.withoutAssets = (-not $IncludeAssets)
            }
        }
    }

    process
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
                InvokeImmichRestMethod -Method Get -RelativePath "/albums/$AlbumId" -ImmichSession:$Session -QueryParameters $QueryParameters | AddCustomType IMAlbum
            }
        }
    }

}
#endregion
