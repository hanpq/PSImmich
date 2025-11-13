function Get-IMFace
{
    <#
    .SYNOPSIS
        Retrieves detected faces from Immich assets
    .DESCRIPTION
        Retrieves information about faces detected in one or more Immich assets. This includes face detection
        data, bounding boxes, and any associated person identifications from facial recognition.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the asset(s) to retrieve face information for. Accepts pipeline input and multiple values.
    .EXAMPLE
        Get-IMFace -Id 'asset-uuid'

        Retrieves all detected faces for the specified asset.
    .EXAMPLE
        @('asset1-uuid', 'asset2-uuid') | Get-IMFace

        Retrieves face information for multiple assets via pipeline.
    .EXAMPLE
        Get-IMAsset -Random -Count 5 | Get-IMFace

        Gets face detection data for 5 random assets.
    .EXAMPLE
        Get-IMFace -Id 'asset-uuid' | Where-Object {$_.person}

        Retrieves faces that have been identified as specific persons.
    .NOTES
        Requires that face detection has been run on the assets. Use Start-IMJob with 'faceDetection' to process assets for face detection.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('assetId')]
        [string[]]
        $Id

    )

    process
    {
        $Id | ForEach-Object {
            $CurrentID = $PSItem
            $QueryParameters = @{
                id = $CurrentID
            }
            InvokeImmichRestMethod -Method GET -RelativePath '/faces' -ImmichSession:$Session -QueryParameters:$QueryParameters
        }
    }
}
#endregion
