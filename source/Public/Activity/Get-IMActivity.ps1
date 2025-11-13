function Get-IMActivity
{
    <#
    .DESCRIPTION
        Retreives album activity
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines the album to retreive activities for.
    .PARAMETER assetId
        Defines a asset to retreive activities for.
    .PARAMETER level
        Defines the level of activities to retreive, valid values are album or asset.
    .PARAMETER type
        Defines the type of activities to retreive, valid values are comment or like.
    .PARAMETER userId
        Defines a specific user to retreive activities for.
    .EXAMPLE
        Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retreives all activities for an album
    .EXAMPLE
        Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'

        Retreives all activities for an album and a specific asset
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('albumId')]
        [string]
        $AlbumId,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('assetId')]
        [string]
        $AssetId,

        [Parameter()]
        [ValidateSet('album', 'asset')]
        [ApiParameter('level')]
        [string]
        $Level,

        [Parameter()]
        [ValidateSet('comment', 'like')]
        [ApiParameter('type')]
        [string]
        $Type,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('userId')]
        [string]
        $UserId
    )

    begin
    {
        $QueryParameters = @{}
        $QueryParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/activities' -ImmichSession:$Session -QueryParameters $QueryParameters | AddCustomType IMActivity
    }

}
#endregion
