function New-IMFace
{
    <#
    .SYNOPSIS
        Creates a new face detection for an asset
    .DESCRIPTION
        Creates a new face that has not been discovered by facial recognition. The content of the bounding box is considered a face.
        This is useful for manually marking faces that the automatic face detection might have missed.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER AssetId
        The UUID of the asset to create a face detection for.
    .PARAMETER PersonId
        The UUID of the person this face belongs to.
    .PARAMETER X
        The X coordinate of the top-left corner of the face bounding box.
    .PARAMETER Y
        The Y coordinate of the top-left corner of the face bounding box.
    .PARAMETER Width
        The width of the face bounding box.
    .PARAMETER Height
        The height of the face bounding box.
    .PARAMETER ImageWidth
        The width of the full image.
    .PARAMETER ImageHeight
        The height of the full image.
    .EXAMPLE
        New-IMFace -AssetId 'asset-uuid' -PersonId 'person-uuid' -X 100 -Y 150 -Width 200 -Height 250 -ImageWidth 1920 -ImageHeight 1080

        Creates a new face detection at the specified coordinates for the given asset and person.
    .EXAMPLE
        $FaceData = @{
            AssetId = 'asset-uuid'
            PersonId = 'person-uuid'
            X = 100
            Y = 150
            Width = 200
            Height = 250
            ImageWidth = 1920
            ImageHeight = 1080
        }
        New-IMFace @FaceData

        Creates a face detection using parameter splatting.
    .NOTES
        All coordinate and dimension parameters are required. The bounding box coordinates should be relative to the full image dimensions.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('assetId')]
        [string]
        $AssetId,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('personId')]
        [string]
        $PersonId,

        [Parameter(Mandatory)]
        [ApiParameter('x')]
        [int]
        $X,

        [Parameter(Mandatory)]
        [ApiParameter('y')]
        [int]
        $Y,

        [Parameter(Mandatory)]
        [ApiParameter('width')]
        [int]
        $Width,

        [Parameter(Mandatory)]
        [ApiParameter('height')]
        [int]
        $Height,

        [Parameter(Mandatory)]
        [ApiParameter('imageWidth')]
        [int]
        $ImageWidth,

        [Parameter(Mandatory)]
        [ApiParameter('imageHeight')]
        [int]
        $ImageHeight
    )

    $BodyParameters = @{}
    $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

    InvokeImmichRestMethod -Method POST -RelativePath '/faces' -ImmichSession:$Session -Body:$BodyParameters

}
#endregion
