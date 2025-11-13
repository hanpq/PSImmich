function Add-IMActivity
{
    <#
    .DESCRIPTION
        Adds a new activity to an album
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines which album to add the activity to.
    .PARAMETER assetId
        Defines a specific assetid to add activities for.
    .PARAMETER comment
        Defines the comment to add.
    .PARAMETER type
        Defines the type of activity to add, valid values are comment or like.
    .EXAMPLE
        Add-IMActivity -AlbumId <albumid> -AssetId <assetid> -Comment 'Great picture!' -Type comment

        Adds a new comment to an asset in the specified album
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
        [ApiParameter('comment')]
        [string]
        $Comment,

        [Parameter()]
        [ValidateSet('comment', 'like')]
        [ApiParameter('type')]
        [string]
        $Type
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/activities' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
